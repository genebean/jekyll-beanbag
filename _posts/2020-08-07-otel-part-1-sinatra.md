---
title: 'OpenTelemetry Part 1: Sinatra'
date: 2020-08-07 18:27 -0400
description: >-
  OpenTelemetry (aka OTel) is becoming the standard for distributed tracing. This is the first in a multi-part series where I will document my trials, tribulations, and successes along the road of using OTel to instrument multiple applications. The first few are all ruby applications and some that I hope to be able to do later are written in Java. My goal is to instrument the applications using one or more standards-compliant libraries and then send the spans to an OTel collector. The OTel collector will then send them on to one or more backends such as Jaeger, Lightstep, and/or Datadog.
---

[OpenTelemetry](https://opentelemetry.io/) (aka OTel) is becoming the standard for distributed tracing. This is the first in a multi-part series where I will document my trials, tribulations, and successes along the road of using OTel to instrument multiple applications. The first few are all ruby applications and some that I hope to be able to do later are written in Java. My goal is to instrument the applications using one or more standards-compliant libraries and then send the spans to an OTel collector. The OTel collector will then send them on to one or more backends such as [Jaeger](https://www.jaegertracing.io/), [Lightstep](https://lightstep.com/), and/or [Datadog](https://www.datadoghq.com/).

## The applications

I figure all of this will make more sense with a touch of context, so here goes. The applications I am starting with are all part of the Continuous Integration (CI) pipeline my team operates at work. They are:

- **CITH, aka CI Triage Helper**: a tool for analyzing data from several [Jenkins](https://www.jenkins.io/) instances and the MongoDB database behind a plugin installed on each called [Build Failure Analyzer](https://plugins.jenkins.io/build-failure-analyzer/).
- **[VMPooler](https://github.com/puppetlabs/vmpooler)**: a tool for managing the lifecycle of the thousands of VMs we run tests on every day.
- **NSPooler, aka NonStandard Pooler**: provides functionality to execute the operations required to reset/destroy/create clean environments to build and test on devices and virtualization technologies not supported by vSphere. This includes platforms virtualized with KVM and libvirt, AIX LPARs, Solaris LDOMs, and Cisco switches.
- **ABS, aka Always Be Scheduling**: a (host) resource scheduler for our CI system. The resources it schedules come from VMPooler, NSPooler, and AWS.

CITH has a [React](https://reactjs.org/) frontend and a ruby [Sinatra](http://sinatrarb.com/) backend. It doesn't interact with the other three at all, which is what makes it a good starting point. It also sits parallel to the CI pipeline instead of within it. This makes it safer to experiment with.

The other three communicate with each other constantly so they will have much more interesting data to look at but it also takes more work to get them deployed as they are critical components within our CI pipeline. There are two data paths for these applications:

1. Jenkins > ABS > (VMPooler, NSPooler, and/or AWS)
2. Developer via ([vmfloaty](https://github.com/puppetlabs/vmfloaty), [Beaker](https://github.com/voxpupuli/beaker), or [Litmus](https://github.com/puppetlabs/puppet_litmus)) > ABS > (VMPooler, NSPooler, and/or AWS)

The applications I hope to get to after these are some of the ones [Puppet](https://puppet.com/) produces, both open and closed source.

## Instrumenting Sinatra

The first application to instrument is CITH. As mentioned above, it sits outside our CI pipeline so it's an easier one to mess with. React is outside my wheelhouse enough that I decided to focus on the backend alone for now. It's written in ruby using the Sinatra framework and the [Puma](https://github.com/puma/puma) web server. With this in mind, I started looking at how to get the job done and found that there are a number of libraries that can automate a lot of the work of tracing a Sinatra applications. With that being the case let's take a look at the contenders before moving on:

### jaeger-client

[jaeger-client](https://github.com/salemove/jaeger-client-ruby) is the only one of these I had looked at before starting on this adventure. From what I understand, it's the standard for instrumenting applications via the [OpenTracing](https://opentracing.io/) standard. This library works great but is missing a key feature I am looking for: automated instrumentation.

### ddtrace

[ddtrace](https://github.com/DataDog/dd-trace-rb) is the gem behind [Datadog's guide](https://docs.datadoghq.com/tracing/setup/ruby/) for tracing ruby applications. It does some awesome stuff with regards to automated instrumentation but only emits data in Datadog's format.

### ls-trace

[ls-trace](https://github.com/lightstep/ls-trace-rb) is a fork of ddtrace and is the gem behind Lightstep's [Ruby Auto-Instrumentation guide](https://docs.lightstep.com/docs/ruby-auto-instrumentation). Like the upstream gem, it only emits data in Datadog's format.

### signalfx-tracing

[signalfx-tracing](https://github.com/signalfx/signalfx-ruby-tracing) is a gem I found via some lucky [DuckDuckGo](https://duckduckgo.com/) searching that seems to do the automated instrumentation like ddtrace but emits data in a Jaeger-compatible format. I briefly tried this out but found that it wasn't quite as automated as I'd hoped and had a heck of a time getting it to actually send the data the way it's supposed to.

### opentelemetry-instrumentation-sinatra

Let me start this section by saying that OpenTelemetry is still very much evolving and the ruby libraries are not evolving as fast as the ones for several other programing languages. This makes finding good, or complete, information really difficult. Having said that, I did some spelunking in [https://github.com/open-telemetry/opentelemetry-ruby](https://github.com/open-telemetry/opentelemetry-ruby) and came across a folder under "instrumentation" called "sinatra." After some digging around in the example code and the library itself I determined it had the automated instrumentation part. After a bit more digging I found that the "exporters" folder contained a "jaeger" library and could emit in a standard format: Thrift's compact encoding. Thus, the first library that seems to fit all my needs.

## Instrumenting, round 1

All this research wasn't done upfront because I didn't realize how much I didn't know. Initially, a coworker and I started down this path by way of spending some hack time plugging in ls-trace to CITH and sending the traces to a free trial account on their service. This worked, and was quite easy to do, so I spent the next few Friday's repeating the process on ABS and NSPooler. The Friday after that is where things went off the rails.

## Wait... what?

There are lots of pieces of info about OpenTracing, and even OpenTelemetry, on Datadog's site that I had been reading... and misunderstanding. You see, I thought they were saying that ddtrace and, by extension, ls-trace could emit spans in one of those formats. It seems this is not actually the case but rather that I could use those standards in my application and then emit them in Datadog's format. This discovery was what one might call a setback as my planned activities for the Friday after having instrumented ABS and NSpooler was to deploy an [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/about/), point ls-trace's output from each to it, and then forward it on to both my internal test instance of Jaeger and to Lightstep. Time to do the research that lead to the list of info above.

## Starting over

After doing a ton of reading I determined that I need to break this work into two main parts:

1. do a minimal poof-of-concept with whatever I found via my research to see if it actually works
2. then go back and redo CITH, ABS, and NSPooler

Naturally, I wasn't thrilled about part two. Unfortunately that's just the way it goes sometimes though when you are learning new stuff.

## Step 1: sinatra-otel-demo

To validate the things I was reading about with regards to the libraries above, I created a simple Sinatra application to test with: [sinatra-otel-demo](https://github.com/genebean/sinatra-otel-demo). After several iterations I now have a Docker container that responds to any requested page with "Hello world!" followed by how many seconds it slept for before rendering the page. The idea here is to cause it to respond randomly on each request so that different span information will be generated. The resulting container is published as [genebean/sinatra-otel-demo](https://hub.docker.com/r/genebean/sinatra-otel-demo) on Docker Hub.

The source repository also contains a docker-compose.yaml that sets up a Jaeger instance to collect it's spans while running locally. Once I FINALLY got spans showing up in this local instance of Jaeger it was time to move on to working in Kubernetes.

### k8s time

#### sinatra-otel-demo

The first step was to deploy [genebean/sinatra-otel-demo](https://hub.docker.com/r/genebean/sinatra-otel-demo) to Kubernetes and send its spans to the test instance of Jaeger that was already running there. The first challenge I had to overcome here was that the output from my application was directed at UDP port 6831 instead of one of the TCP ports that Jaeger's ingress was listening on. Fortunately, during my research I learned that Jaeger's documentation contained this lovely piece of information: [Manually Defining Jaeger Agent Sidecars](https://www.jaegertracing.io/docs/1.18/operator/#manually-defining-jaeger-agent-sidecars). With that in mind I started crafting a [Helm](https://helm.sh/) chart to manage my deployment and came up with this:

{% raw %}

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "sinatra-otel-demo.fullname" . }}
  labels:
    {{- include "sinatra-otel-demo.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "sinatra-otel-demo.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "sinatra-otel-demo.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}-app
          image: genebean/sinatra-otel-demo:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 9292
              name: http
              protocol: TCP
          securityContext:
            {{- toYaml .Values.securityContext.app | nindent 12 }}
        - name: {{ .Chart.Name }}-jaeger-agent
          image: jaegertracing/jaeger-agent:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5778
              name: config-rest
              protocol: TCP
            - containerPort: 6831
              name: jg-compact-trft
              protocol: UDP
            - containerPort: 14271
              name: admin-http
              protocol: TCP
          args:
            - --reporter.grpc.host-port={{ .Values.jaeger_host }}:14250
            - --reporter.type=grpc
            - --agent.tags=helm_chart={{ include "sinatra-otel-demo.chart" . }}
          securityContext:
            {{- toYaml .Values.securityContext.jaeger | nindent 12 }}
```

{% endraw %}

The deployment above places both `genebean/sinatra-otel-demo` and `jaegertracing/jaeger-agent` in the same pod. This allows the agent to listen for the traces emitted over UDP, collect them, and then send them back out in "model.proto" format via gRPC to the Jaeger server.

I got that running in my cluster and was able to see traces in Jaeger, which I was stupid excited about considering how long of a road it had been to get to this point.

#### OTel collector

Now that I had data going directly to Jaeger it was time to stick an OTel collector in between the two so that I could, eventually, send the same data to multiple destinations (Jaeger and one or more hosted services). I was able to get the collector deployed quite easily by packaging up what is talked about in the Kubernetes section of [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/about/) and combining it with a sample configuration a gentleman at [Grafana](https://grafana.com/) shared with me. The only problem with the info from the OTel website was this bit in the Agent section:

> It is recommended to deploy the Agent on every host within an environment. In doing so, the Agent is capable of adding metadata to observability data it receives or collects. In addition, the Agent can offload responsibilities that client instrumentation would otherwise need to handle including batching, retry, encryption, compression, and more.

Based on this, it seems pretty clear to me that the intent is to send the data from the application to the agent that resides on the same compute node. That sound logical enough but there is actually nothing in the provided Kubernetes resources to make that happen. Upon research this, it turns out this is actually a pretty hard problem to solve. In the end, I simply removed the DaemonSet of agents that were initially deployed.

With yet another hurdle cleared I pointed the Jaeger sidecar agent directly to the collector and promptly saw spans still being delivered to my test instance of Jaeger.

### Wrapping up the deployments

With things working as intended for step 1 I spent some time polishing up my Helm charts for sinatra-otel-demo and the OTel collector. Before lunch today I had a pull request up to our internal chart repository for these. Once that PR gets reviewed and merged I will finalize my application definitions for [Argo CD](https://argoproj.github.io/projects/argo-cd) so that the deployment is repeatable and managed.

## Next steps

My next step is to start on step 2 from above by redoing the instrumentation on CITH. To do that I first have one key question outstanding that I still need to make sure I have an answers for: is there a way to set tags using the OTel libraries? That is key because there are some pieces of information, such as version number, that should be passed as a tag from CITH. If I can't do that with the instrumentation from OTel then I will have to do like sinatra-otel-demo is currently doing via its deployment and set those tags somehow with a Jaeger sidecar. Hopefully that won't end up being the case though.
