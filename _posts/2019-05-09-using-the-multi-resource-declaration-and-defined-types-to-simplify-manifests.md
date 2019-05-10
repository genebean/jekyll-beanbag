---
author: gene
---
Sometimes it seems you just keep repeating the same block of code with only one or two lines changed. Sometimes a single thing you need to do more than once is made up of the same two or three resources. These two scenarios are ones that I experience fairly often.

They are also ones I regularly observe when doing code reviews for others. I am often met with interest and a response that is along the lines of “I didn’t know you could do that” when I mention the idea of simplifying the code I am reviewing by using a multi-resource declaration or a defined type. This post will introduce you to multi-resource declarations and defined types and then walk you through a real-world example of putting them to use to configure load balancing of Puppet Enterprise's services.

## Multi-resource declarations

Did you know that these two blocks of code are actually identical in function?

![standard vs condensed screenshot]({{ "/assets/images/posts/standard-vs-condensed.png" | relative_url }})

The version on the right is an example of a multi-resource declaration. It's not only shorter but it also centralizes the lines that are duplicated in the standard version to a `default` block. This makes for easier upkeep as you have fewer places to edit common parameters like `require` and `notify`. Details on the format of a multi-resource declaration can be found in the [Language: Resources (advanced)](https://puppet.com/docs/puppet/6.4/lang_resources_advanced.html) docs.

## Defined types

To quote [the docs](https://puppet.com/docs/puppet/6.4/lang_defined_types.html):

> Defined resource types (also called defined types or defines) are blocks of Puppet code that can be evaluated multiple times with different parameters. Once defined, they act like a new resource type: you can cause the block to be evaluated by declaring a resource of that new resource type.

One of the best examples of this is the chunk of code in the [puppetlabs/apache](https://forge.puppet.com/puppetlabs/apache#configuring-virtual-hosts) module that allows you to create multiple Apache vhosts. As a user, you write something as simple as the example below. Everything else will be done by the defined type.

```puppet
apache::vhost { 'redirect.example.com non-ssl':
  servername      => 'redirect.example.com',
  port            => '80',
  docroot         => '/var/www/redirect',
  redirect_status => 'permanent',
  redirect_dest   => 'https://redirect.example.com/'
}

apache::vhost { 'redirect.example.com ssl':
  servername => 'redirect.example.com',
  port       => '443',
  docroot    => '/var/www/redirect',
  ssl        => true,
}
```

Internally the puppet manifest that defines an `apache::vhost` containing a whopping 1111 lines of code! Check it out for yourself [here](https://github.com/puppetlabs/puppetlabs-apache/blob/4.1.0/manifests/vhost.pp).

This is a prime example of how using a defined type provides you with two very real benefits:

1. reusable code: you are able to use the block of code as shown in the example above to create multiple unique instances of the same "thing" (a vhost in this case).
2. shorter, more readable profiles: when configuring an Apache web server you are able to create the two vhosts with just a few lines of code instead of all that would be needed without the abstraction of the logic into the defined type `apache::vhost`.

## Exploring a real-world use case

Most of us probably are not going to write a defined type that is 1000+ lines of code but that doesn't mean we can't benefit from them anyhow. The rest of this post will walk you through a real-world example of how using defined types and multi-resource declarations drastically simplified and shortened some code in use by my team at Puppet.

### The task at hand: load balancing Puppet Enterprise

I work on the InfraCore team as part of Developer Services at Puppet. I recently set out to rework the load balancers our team fronts Puppet Enterprise with internally. I had the following two goals for this work:

1. route every service provided by our Puppet Enterprise installation through our HAProxy load balancers
2. use [Consul](https://www.consul.io/) with HAProxy's "server-template" to automatically populate the backend server or servers for each service instead of PuppetDB

### Round 1: an unreadable manifest

My first pass at this generated a profile that configured HAProxy correctly but was nearly impossible to follow. I made things a bit better by converting all the individual `haproxy::listen` and `haproxy::balancermember` resources into multi-resource declarations. This helped make each group of resources easier to maintain while simultaneously ensuring the backend for a frontend was nowhere near it in the manifest (which is less than ideal). The manifest was laid out in this order:

1. Nine different `haproxy::listen` resources then
2. Three variables that each defined a non-trivial `puppetdb_query` then
3. A `.each` loop for each of the three variables that defined the `haproxy::balancermember` resources that corresponded to the `haproxy::listen` defined earlier.

Here's what that looked like:

```puppet
haproxy::listen {
  default:
    collect_exported => false,
    ipaddress        => '*',
    require          => File[
      $puppet_ca_file,
      $puppet_crl_file,
    ],
  ;
  'pe-console-80':
    ports   => '80',
  ;
  'pe-console-443':
    ports   => '443',
  ;
  'rbac-api':
    ports   => '4433',
    options => {
      'option httpchk' => 'get /status/v1/simple',
    },
  ;
  'puppet-agent':
    ports   => '8140',
    options => {
      'option httpchk' => 'get /status/v1/simple/master',
    },
  ;
  'pxp-agent':
    ports   => '8142',
    options => {
      'option httpchk' => 'get /status/v1/simple',
      'timeout'        => 'tunnel 15m',
    },
  ;
  'orchestrator-api':
    ports   => '8143',
    options => {
      'option httpchk' => 'get /status/v1/simple',
    },
  ;
  'puppetdb-api':
    ports   => '8081',
    options => {
      'option httpchk' => 'get /status/v1/simple',
    },
  ;
  'code-manager-api':
    ports   => '8170',
    options => {
      'option httpchk' => 'get /status/v1/simple/code-manager-service',
    },
  ;
  'stats-page':
    ports   => '9000',
    options => {
      'mode'   => 'http',
      'option' => [
        'httplog',
      ],
      'stats'  =>[
        'uri /',
        'realm HAProxy\ Statistics',
        'admin if TRUE',
      ],
    },
  ;
}

$compilers = puppetdb_query("inventory {
  facts.classification.stage = '${facts['classification']['stage']}' and
  facts.classification.context = '${facts['classification']['context']}' and
  resources {
    type = 'Class' and
    title = 'Role::Pe::Compiler'
  }
}")

$consoles = puppetdb_query("inventory {
  facts.classification.stage = '${facts['classification']['stage']}' and
  facts.classification.context = '${facts['classification']['context']}' and
  resources {
    type = 'Class' and
    title = 'Puppet_enterprise::Profile::Console'
  }
}")

$puppetdbs = puppetdb_query("inventory {
  facts.classification.stage = '${facts['classification']['stage']}' and
  facts.classification.context = '${facts['classification']['context']}' and
  resources {
    type = 'Class' and
    title = 'Puppet_enterprise::Profile::Puppetdb'
  }
}")

$compilers.each |$node| {
  haproxy::balancermember {
    default:
      server_names => $node['facts']['networking']['fqdn'],
      ipaddresses  => $node['facts']['networking']['ip'],
      options      => [
        'check check-ssl',
        'port 8140', # explicitly set to the agent port
        'verify required',
        "ca-file ${puppet_ca_file}",
        "crl-file ${puppet_crl_file}",
      ],
      require      => File[
        $puppet_ca_file,
        $puppet_crl_file,
      ],
    ;
    "${node['certname']}_${node['facts']['networking']['ip']}_puppet_agent":
      listening_service => 'puppet-agent',
      ports             => '8140',
    ;
    "${node['certname']}_${node['facts']['networking']['ip']}_pxp_agent":
      listening_service => 'pxp-agent',
      ports             => '8142',
    ;
  }
}

$consoles.each |$node| {
  haproxy::balancermember {
    default:
      server_names => $node['facts']['networking']['fqdn'],
      ipaddresses  => $node['facts']['networking']['ip'],
      options      => ['check'],
      require      => File[
        $puppet_ca_file,
        $puppet_crl_file,
      ],
    ;
    "${node['certname']}_${node['facts']['networking']['ip']}_console_80":
      listening_service => 'pe-console-80',
      ports             => '80',
    ;
    "${node['certname']}_${node['facts']['networking']['ip']}_console_443":
      listening_service => 'pe-console-443',
      ports             => '443',
    ;
    "${node['certname']}_${node['facts']['networking']['ip']}_rbac_api_4433":
      listening_service => 'rbac-api',
      ports             => '4433',
      options           => [
        'check check-ssl',
        'port 4433',
        'verify required',
        "ca-file ${puppet_ca_file}",
        "crl-file ${puppet_crl_file}",
      ],
    ;
    "${node['certname']}_${node['facts']['networking']['ip']}_orchestrator_api_8143":
      listening_service => 'orchestrator-api',
      ports             => '8143',
      options           => [
        'check check-ssl',
        'port 8143',
        'verify required',
        "ca-file ${puppet_ca_file}",
        "crl-file ${puppet_crl_file}",
      ],
    ;
    "${node['certname']}_${node['facts']['networking']['ip']}_code_manager_api_8170":
      listening_service => 'code-manager-api',
      ports             => '8170',
      options           => [
        'check check-ssl',
        'port 8140', # explicitly set to the agent port
        'verify required',
        "ca-file ${puppet_ca_file}",
        "crl-file ${puppet_crl_file}",
      ],
    ;
  }
}

$puppetdbs.each |$node| {
  haproxy::balancermember { "${node['certname']}_${node['facts']['networking']['ip']}_puppetdb_api":
    listening_service => 'puppetdb-api',
    ports             => '8081',
    server_names      => $node['facts']['networking']['fqdn'],
    ipaddresses       => $node['facts']['networking']['ip'],
    options           => [
      'check check-ssl',
      'port 8081',
      'verify required',
      "ca-file ${puppet_ca_file}",
      "crl-file ${puppet_crl_file}",
    ],
    require           => File[
      $puppet_ca_file,
      $puppet_crl_file,
    ],
  }
}
```

If you can easily follow what's going on in that chunk of code you are doing better than me...

### Round 2: a defined type

Even though the first round "worked", I wasn't happy with it. After mulling things over a bit and looking at the code taken to create the frontend and backend I realized there was a fair amount of overlap between the two. This was also the point at which I decided to switch to using HAProxy’s server-template backed by Consul to replace PuppetDB queries so that updates to the backend servers were more real-time. Switching to a server-template also meant that changes to the list of servers providing the backend service would not require HAProxy to restart. With that in mind, I decided to try making a defined type that took care of creating both the frontend and backend resources. I also wanted to save others from the same aggravation while I was at it so I created the [ploperations/haproxy_consul](https://forge.puppet.com/ploperations/haproxy_consul) module instead of hiding the code away in my control repo. The result is that I was able to replace the code above with this:

```puppet
haproxy_consul::server_template {
  default:
    consul_domain => $_consul_domain,
    amount        => '1',
    require       => Class['Haproxy_consul::Puppet_ca_files'],
  ;
  'pe-console-http':
    ports                  => '80',
    listen_options         => {
      'balance' => 'roundrobin',
      'option'  => [
        'httpchk',
      ],
    },
    balancermember_options => [
      'resolvers consul',
      'resolve-prefer ipv4',
      'check',
    ],
  ;
  'pe-console-https':
    ports                  => '443',
    listen_options         => {
      'balance' => 'roundrobin',
      'option'  => [
        'ssl-hello-chk',
      ],
    },
    balancermember_options => [
      'resolvers consul',
      'resolve-prefer ipv4',
      'check',
    ],
  ;
  'pe-rbac-api':
    ports                  => '4433',
    listen_options         => {
      'option httpchk' => 'get /status/v1/simple',
    },
    balancermember_options => [
      'resolvers consul',
      'resolve-prefer ipv4',
      'check check-ssl',
      'port 4433',
      'verify required',
      "ca-file ${_puppet_ca_file}",
      "crl-file ${_puppet_crl_file}",
    ],
  ;
  'pe-puppetdb-api':
    ports                  => '8081',
    listen_options         => {
      'option httpchk' => 'get /status/v1/simple',
    },
    balancermember_options => [
      'resolvers consul',
      'resolve-prefer ipv4',
      'check check-ssl',
      'port 8081',
      'verify required',
      "ca-file ${_puppet_ca_file}",
      "crl-file ${_puppet_crl_file}",
    ],
  ;
  'pe-compiler-puppet-agent':
    ports                  => '8140',
    listen_options         => {
      'option httpchk' => 'get /status/v1/simple/master',
    },
    balancermember_options => [
      'resolvers consul',
      'resolve-prefer ipv4',
      'check check-ssl',
      'port 8140',
      'verify required',
      "ca-file ${_puppet_ca_file}",
      "crl-file ${_puppet_crl_file}",
    ],
    amount                 => '8',
  ;
  'pe-compiler-pxp-agent':
    ports                  => '8142',
    listen_options         => {
      'option httpchk' => 'get /status/v1/simple',
      'timeout'        => 'tunnel 15m',
    },
    balancermember_options => [
      'resolvers consul',
      'resolve-prefer ipv4',
      'check check-ssl',
      'port 8140', # explicitly set to the agent port
      'verify required',
      "ca-file ${_puppet_ca_file}",
      "crl-file ${_puppet_crl_file}",
    ],
    amount                 => '8',
  ;
  'pe-orchestrator-api':
    ports                  => '8143',
    listen_options         => {
      'option httpchk' => 'get /status/v1/simple',
    },
    balancermember_options => [
      'resolvers consul',
      'resolve-prefer ipv4',
      'check check-ssl',
      'port 8143',
      'verify required',
      "ca-file ${_puppet_ca_file}",
      "crl-file ${_puppet_crl_file}",
    ],
  ;
  'pe-code-manager-api':
    ports                  => '8170',
    listen_options         => {
      'option httpchk' => 'get /status/v1/simple/code-manager-service',
    },
    balancermember_options => [
      'resolvers consul',
      'resolve-prefer ipv4',
      'check check-ssl',
      'port 8140', # explicitly set to the agent port
      'verify required',
      "ca-file ${_puppet_ca_file}",
      "crl-file ${_puppet_crl_file}",
    ],
  ;
}

haproxy::listen { 'stats-page':
  collect_exported => false,
  ipaddress        => '*',
  ports            => '9000',
  options          => {
    'mode'   => 'http',
    'option' => [
      'httplog',
    ],
    'stats'  =>[
      'uri /',
      'realm HAProxy\ Statistics',
      'admin if TRUE',
    ],
  },
}
```

This is a prime example of how combining a defined type (`haproxy_consul::server_template`) and a multi-resource declaration can make for much more readable and maintainable code. Now, let's dive into what's going on in this example...

### Diving into the new defined type

The code above has two distinct things:

1. a set of `haproxy_consul::server_template` resources
2. a single `haproxy::listen` resource for the stats page (it doesn't get a backend defined)

Here's what's happening inside the `haproxy_consul::server_template` defined type (you can also see this on GitHub [here](https://github.com/ploperations/ploperations-haproxy_consul/blob/master/manifests/server_template.pp)):

```puppet
# Comments omitted
define haproxy_consul::server_template (
  Variant[String[1], Array[String[1]]] $ports,
  String[1]                            $amount,
  Stdlib::Fqdn                         $consul_domain,
  String[1]                            $ipaddress              = '*',
  Optional[Hash]                       $listen_options         = undef,
  Optional[Array[String[1]]]           $balancermember_options = undef,
) {
  include haproxy

  haproxy::listen { $title:
    collect_exported => false,
    ipaddress        => $ipaddress,
    ports            => $ports,
    options          => $listen_options,
  }

  haproxy::balancermember { $title:
    listening_service => $title,
    type              => 'server-template',
    ports             => $ports,
    prefix            => $title,
    amount            => $amount,
    fqdn              => "_${title}._tcp.service.${consul_domain}",
    options           => $balancermember_options,
  }
}
```

All I have done here is put the different resources needed for a single frontend and backend HAProxy service that is backed by Consul into a separate manifest, declared some parameters for the info needed to create those resources, and started the manifest with `define` instead of `class`. Back in the multi-resource declaration, I then defined a few default values that I wanted to pass to at least the majority of my services and followed that up with instances of this new type just like what was done with the `file` resources back at the beginning of this post.

### Going a few steps further

Since I was making a module out of this anyhow, I figured it would be good to extract a few more pieces of code from this project too.  The end result was a module that also provides:

- a simplified way to make your Consul server listen on port 53 via the `dns_on_53` class
- a reusable block of code for setting up connection validation between HAProxy and something using your Puppet CA via the `puppet_ca_files` class
- a defined type named `resolver` that sets up a resolver in HAProxy that points at your Consul cluster

Seeing as this post is focusing on defined types let's take a look at the other one in the module:

```puppet
# Comments omitted
define haproxy_consul::resolver(
  Stdlib::Httpurl $consul_server = $title,
  String[1] $resolver_name = 'consul',
  Integer $resolve_retries = 3,
  Hash $timeout = { 'retry' => '2s' },
  Optional[Hash] $hold = undef,
) {
  include haproxy

  $consul_name_servers = consul_data::get_service_nodes($consul_server, 'consul')
  $consul_dns_port = pick(consul_data::get_key($consul_server, 'consul-dns/port'), '8600')

  $nameserver_hash = $consul_name_servers.reduce( {} ) |$memo, $nameserver| {
    $memo + { "${nameserver['Node']}" => "${nameserver['Address']}:${consul_dns_port}" }
  }

  haproxy::resolver { $resolver_name:
    nameservers           => $nameserver_hash,
    resolve_retries       => $resolve_retries,
    timeout               => $timeout,
    hold                  => $hold,
    accepted_payload_size => 8192,
  }
}
```

This allows you to have Puppet query your Consul server for a list of nodes providing the 'consul' service and use those nodes as the resolvers defined in HAProxy. With this code you could easily set up both a test and a production resolver on the same HAProxy instance and then point some services to each one by doing something similar to this:

```puppet
haproxy_consul::resolver {
  'https://consul-app-prod-1.example.com:8500':
    resolver_name = 'prod-consul'
  ;
  'https://consul-app-test-1.example.com:8500':
    resolver_name = 'test-consul'
  ;
}
```

With the above in place you would be able to add either `resolvers prod-consul` or `resolvers test-consul` to the `balancermember_options` of each `haproxy_consul::server_template` resource similar to how the example earlier had `resolvers consul` defined for each one.

## Wrapping up

Hopefully this gives you some ideas that you can use to simplify your own code. As mentioned earlier, you can find the `haproxy_consul` module on the Puppet Forge at https://forge.puppet.com/ploperations/haproxy_consul and you can see its source code on GitHub at https://github.com/ploperations/ploperations-haproxy_consul.

*Gene Liverman is a senior site reliability engineer at Puppet.*
