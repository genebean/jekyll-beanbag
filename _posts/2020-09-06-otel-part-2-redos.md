---
title: 'OpenTelemetry Part 2: Redoing Instrumentation'
date: 2020-09-06 21:30 -0400
description: >-
  For part two of my journey in using OpenTelemetry (Otel) with Sinatra I am replacing my Lightstep instrumentation with the OTel version. Besides updating the instrumentation, I am also deploying production instances of an OTel Collector and Jaeger. The goal of part 2 is to have my first three applications shipping traces to both a local Jaeger instance and to Lightstep in both test and production and to have Jaeger included in the Docker compose workflows used during development.
---

For part two of my journey in using OpenTelemetry (Otel) with Sinatra I am replacing my Lightstep instrumentation with the OTel version. Besides updating the instrumentation, I am also deploying production instances of an OTel Collector and Jaeger. The goal of part 2 is to have my first three applications shipping traces to both a local Jaeger instance and to Lightstep in both test and production and to have Jaeger included in the Docker compose workflows used during development.

> **Note:** Be sure to also see part 3 of this series as some limitations talked about here no longer exist. I am leaving them in this part because they are a relevant part of my journey.

## Recapping current reality

To set the stage for this phase I want to recap where things are:

- There is a pre-existing Jaeger instance deployed to my test GKE environment that was setup over a year ago as part of another project
- An OTel collector has been deployed to test also and is shipping to the local Jaeger only
- [genebean/sinatra-otel-demo](https://hub.docker.com/r/genebean/sinatra-otel-demo) has been deployed to test and is shipping traces to the OTel collector
- CITH has Lightstep instrumentation setup and shipping to Lightstep in both test and prod by way of a [Lightstep proxy](https://github.com/lightstep/reverse-proxy) that is deployed as part of the CITH Helm chart
- ABS and NSPooler have Lightstep instrumentation added in but are not yet shipping anywhere
- No full fledged [Lightstep satellites](https://github.com/lightstep/lightstep-satellite-helm-chart) have been deployed yet
- No OTel collector has been deployed to production yet
- ABS and NSPooler are still running in Apache Mesos... they will be moving to Kubernetes soon but not before I implement tracing

## CITH

Just as was done originally, I am starting my new round of instrumentation with our CI Triage Helper (CITH) application. I am doing this because it is the simplest of our applications and because it sits besides our CI pipeline. This makes it much safer to experiment with than one that is directly part of CI.

### Gems

The first step in this conversion is to replace `ls-trace` in the `Gemfile` with the bits from OpenTelemetry. In the case of CITH, that means adding this:

```ruby
gem 'opentelemetry-api', '~> 0.5.1'
gem 'opentelemetry-exporters-jaeger', '~> 0.5.0'
gem 'opentelemetry-instrumentation-restclient', '~> 0.5.0'
gem 'opentelemetry-instrumentation-sinatra', '~> 0.5.0'
gem 'opentelemetry-sdk', '~> 0.5.1'
```

### Configuration

The first change in `config.ru` is updating the requires from simply being `ddtrace` to all the OTel components:

```ruby
require 'opentelemetry-api'
require 'opentelemetry/exporters/jaeger'
require 'opentelemetry-instrumentation-restclient'
require 'opentelemetry-instrumentation-sinatra'
require 'opentelemetry-sdk'
```

The change in `config.ru` is to swap out the configuration block from Lightstep for the one needed by OTel:

#### Lightstep

```ruby
if ENV['CITH_LIGHTSTEP_TRACING_TOKEN']
  puts "CITH_LIGHTSTEP_TRACING_TOKEN was passed so tracing will be enabled."
  Datadog.configure do |c|
    c.use :sinatra
    c.use :mongo
    c.use :rest_client


    c.distributed_tracing.propagation_inject_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]
    c.distributed_tracing.propagation_extract_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]

    c.tracer tags: {
      'lightstep.service_name' => 'cith-api',
      'lightstep.access_token' => ENV['CITH_LIGHTSTEP_TRACING_TOKEN'],
      'service.version' => version,
        service_name: 'cith', host: jaeger_host, port: 6831
    }
  end
else
  puts 'No CITH_LIGHTSTEP_TRACING_TOKEN passed. Tracing is disabled.'
end
```

#### OTel

```ruby
jaeger_host = ENV['JAEGER_HOST'] || 'localhost'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sinatra'
  c.use 'OpenTelemetry::Instrumentation::RestClient'

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::Exporters::Jaeger::Exporter.new(
        service_name: 'cith', host: jaeger_host, port: 6831
      )
    )
  )
end
```

Note that in this configuration block there is nothing about MongoDB... that is because its bits have not been ported over from ddtrace yet (see [issue #257](https://github.com/open-telemetry/opentelemetry-ruby/issues/257)).

#### Jaeger

Another difference here is that the spans are being output to a Jaeger agent... via UDP. As of today, this is the only exporter that OpenTelemetry for ruby has. There is active work to implement others but, in the mean time, this means that some extra steps are needed to deal with the UDP traffic since it's really designed to be sent to localhost. More on this later.

### Local development via docker-compose.yml

CITH, like many of our apps, comes with a `docker-compose.yml` to facilitate local development and testing. In the case of CITH, that file needed a few changes to switch from Lightstep to OTel:

- the passed in list of environment variables was updated to simply be the Jaeger host's address
- the Lightstep proxy was replaced with a Jaeger all-in-one instance

### Done... but not really

This wrapped up all the code changes to CITH and was pretty easy to test out locally. The problem is that this was no where near the end of the road with regards to migrating CITH over to OpenTelemetry: its Helm chart still needed updating and additional infrastructure needed to be deployed.

## Charts, charts, charts

To be able to deploy the new version of CITH and validate everything worked as desired I also needed to update my OTel collector to emit traces to Lightstep and I needed to deploy a Lightstep satellite via their Helm chart. I also needed to deploy these latter two to our production environment along with a Jaeger instance. The way I decided to tackle this was to update CITH's chart so that it could get data to the OTel collector, then deploy a satellite, then update the collector for Lightstep, and finally deal with upgrading the current Jaeger and preparing for deploying an initial one to production.

### CITH's Helm chart

CITH's chart was actually pretty easy: I just needed to delete all the Lightstep related bits from it and add a Jaeger sidecar to the API's pod. The sidecar is able to collect the traces emitted to localhost and then send them via gRPC to the OTel collector. Here are the flags I added to the Jaeger agent:

{% raw %}

```yaml
args:
  - --reporter.grpc.host-port={{ .Values.jaeger_host }}:14250
  - --reporter.type=grpc
  - --jaeger.tags=helm_chart={{ include "dio-cith.chart" . }},service.version={{ .Chart.AppVersion }}
```

{% endraw %}

Breaking those args entries down:

- the first and second ones combined send traces via gRBC to the Jaeger input of the OTel collector
- the third one adds some tags that get converted into OTel attributes

#### Why add a sidecar?

Remember earlier when I mentioned that the Jaeger exporter is really only intended for sending to localhost? Well, that is one reason we need a sidecar. The other is that there isn't currently a way to add tags like `service.version` without using the sidecar. That functionality is coming per work done to fix [#312](https://github.com/open-telemetry/opentelemetry-ruby/issues/312) but, in between now and then, this is what I can do.

### Satellite Deployment

When I started on this phase there wasn't a repository for Lightstep's Helm chart ([#1](https://github.com/lightstep/lightstep-satellite-helm-chart/issues/1)). Fortunately, the fine folks at Lightstep were willing to rectify this and it is now available at both [Artifact HUB](https://artifacthub.io/packages/helm/lightstepsatellite/lightstep) and [Helm Hub](https://hub.helm.sh/charts/lightstepsatellite/lightstep). I deployed their chart and it mostly "just worked" - the exception is that I never did get the statsd metrics coming out of it to work right with a Prometheus statsd exporter. For now I have simply given up on this aspect of monitoring the satellite and, instead, am hoping they implement native Prometheus metrics. Docs for all of this can be found [here](https://docs.lightstep.com/docs/install-and-configure-satellites).

### Collector outputs

With the satellites up and running it is time to add Lightstep as a destination in my collector configuration. Doing so is as simple as adding this to my exporters section and then adding `otlp/lightstep` to the array of locations listed in the exporters part of the pipeline:

{% raw %}

```yaml
otlp/lightstep:
  endpoint: "lightstep.lightstep.svc:8184"
  insecure: true
  headers:
    "lightstep-access-token": {{ .Values.lightstepAccessToken }}
```

{% endraw %}

This simply sets up an exporter that sends data in OTLP format to the service named `lightstep` in the `lightstep` namespace on port 8184 and adds a header that includes the access token that matches the desired project in Lightstep. Fortunately, this is all that is needed to get data to Lightstep - no custom exporter or other hacks at all.

### Jaeger redo

I was actually dreading this step but, thanks to a tip from a coworker, it turned out to be really easy as Jaeger now provides a `jaeger` chart for deploying their their stack via [https://jaegertracing.github.io/helm-charts/](https://jaegertracing.github.io/helm-charts/). For my setup, all I need to do is create a shallow Helm chart that has the `jaeger` chart as a dependency and includes this `values.yaml` file:

```yaml
jaeger:
  provisionDataStore:
    cassandra: false
    elasticsearch: true
  storage:
    type: elasticsearch
  agent:
    enabled: false
  collector:
    autoscaling:
      enabled: true
      minReplicas: 1
      maxReplicas: 3
  query:
    ingress:
      enabled: true
      annotations:
        certmanager.k8s.io/cluster-issuer: letsencrypt-prod
        kubernetes.io/ingress.class: nginx
        kubernetes.io/tls-acme: "true"
      hosts:
        - jaeger-test.k8s.example.net
      tls:
        - hosts:
            - jaeger-test.k8s.example.net
          secretName: jaeger-test.k8s.example.net-tls
```

## Deploying it all

With all this in place I deployed everything to test, and then to production, and was able to see data from CITH in both Jaeger and Lightstep for both 🎉

## ABS and NSPooler

Getting to this point has taken longer than anticipated but has been very fruitful as it has provided what I imagine to be a good foundation for all the other things I plan to do. Getting ABS and NSPooler updated to use this is basically a rinse and repeat of CITH so I am not repeating the details here. The one exception is that they still run in our Mesos cluster so an extra step is needed: I need a place to send their traces. I solved this by taking advantage of a host we had previously setup as a static Docker host. I simply deployed a [Jaeger Agent](https://www.jaegertracing.io/docs/1.18/architecture/#agent) to that host that listened on port 6831/udp and gave it basically the same startup arguments that were used in CITH's Helm chart. This was all done with Puppet code via the [puppetlabs/docker module](https://forge.puppet.com/puppetlabs/docker) and the following entry in [Hiera](https://puppet.com/docs/puppet/latest/hiera_intro.html):

```yaml
---
docker::run_instance::instance:
  jaeger-agent:
    image: 'jaegertracing/jaeger-agent:latest'
    ports:
      - '6831:6831/udp'
    command: '--reporter.grpc.host-port=otel-jgrpc-prod.k8s.example.net:443 --reporter.type=grpc --reporter.grpc.tls.enabled=true --reporter.grpc.tls.skip-host-verify=true'
```

To make this work I also had to add an ingress resource to my OTel collector's deployment. The ingress looks like this:

{% raw %}

```yaml
{{- if .Values.ingress.enabled -}}
{{- $fqdn := .Values.ingress.protocol.jaegerGrpc.fqdn -}}
{{- $nameSuffix := .Values.ingress.protocol.jaegerGrpc.nameSuffix -}}
{{- $svcPortNumber := .Values.ingress.protocol.jaegerGrpc.svcPortNumber -}}
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: {{ include "dio-otel-collector.fullname" . }}-{{ $nameSuffix }}
  labels:
    {{- include "dio-otel-collector.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
  {{- end }}
spec:
  tls:
    - hosts:
        - {{ $fqdn | quote }}
      secretName: {{ $fqdn }}-tls
  rules:
    - host: {{ $fqdn | quote }}
      http:
        paths:
          - path: /
            backend:
              serviceName: otel-collector
              servicePort: {{ $svcPortNumber }}
{{- end }}
```

{% endraw %}

The only thing special about this ingress is this line:

```yaml
nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
```

That ingress is paired with this entry in my `values.yaml` file:

```yaml
ingress:
  enabled: true
  annotations:
    certmanager.k8s.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  protocol:
    jaegerGrpc: 
      fqdn: otel-jgrpc-test.k8s.example.net
      nameSuffix: jaeger-grpc
      svcPortNumber: 14250
```

That line is required to make the gRPC connection actually work. Beyond that, all it's doing is:

1. listening for a gRPC connection over TLS on port 443,
2. terminating the TLS connection once received, and
3. forwarding the unencrypted traffic to the `otel-collector` service on port 14250.

With this in place data started flowing from ABS and NSPooler too!

## What's next?

Part 3 of this series will cover how things changed, and got way better, when version 0.6.0 of the `opentelemetry-*` gems came out. It will also talk about some additional learnings and getting VMPooler added into the mix of things sending tracing data.
