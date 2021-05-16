---
title: 'PuppetDB Queries'
description: >-
  PuppetDB holds tons of usefule info. Here's a glimpse of how you can utilize that info in your puppet manifests.
---

# From slack recently

```puppet
$server_list = puppetdb_query ("resources {
  certname = '${trusted['certname']}' and
  type     = 'Class' and
  title    = 'Puppet_enterprise::Profile::Agent'
}").map |$value| { $value['parameters']['server_list'] }

($server_list).each |$node| {
  $n_facts = puppetdb_query("inventory { certname = '${node}' }")
  $n_name  = $n_facts['facts']['networking']['fqdn']
  $n_ip    = $n_facts['facts']['networking']['ip']

  firewall { "201 allow puppet-agent from ${n_name} via ${n_ip}":
    proto  => 'tcp',
    action => 'accept',
    source => $n_ip,
    dport  => 8140,
  }

  firewall { "201 allow puppetdb from ${n_name} via ${n_ip}":
    proto  => 'tcp',
    action => 'accept',
    source => $n_ip,
    dport  => 8081,
  }
}
```

If you want to filter the initial list of servers by some fact, that is an easy modification. Just adjust it like so:

```puppet
$server_list = puppetdb_query (""inventory {
  facts.foo.bar = '${facts['foo']['bar']}' and
  resources {
    certname = '${trusted['certname']}' and
    type     = 'Class' and
    title    = 'Puppet_enterprise::Profile::Agent'
  }
}").map |$value| { $value['parameters']['server_list'] }
```




## from Jason S on slack

For a postgres clustering profile, we query nodes with the same product/role and use them to configure wal ship and streaming (9.6)

```puppet
$cluster_ipaddresses = puppetdb_query("inventory[facts] {
  facts.product_name ~ '${::product_name}' and
  facts.role         ~ '${profile_postgresql::hostname_lookup_prefix}' and
  facts.dc           ~ '${::dc}'
}").map |$value| { $value['facts']['ipaddress'] }

$archive_enabled_ipaddresses = $cluster_ipaddresses.filter |$value| { $value != $facts['ipaddress'] }

#Return nodes eligible to be streaming_active. Currently only supports failing over between nodes *-001* *-002*
$active_eligible_ipaddresses = puppetdb_query("inventory[facts] {
  facts.product_name ~ '${::product_name}' and
  facts.dc           ~ '${::dc}' and
  facts.role         ~ '${profile_postgresql::hostname_lookup_prefix}'
}").map |$value| { { 'fqdn' => $value['facts']['fqdn'], 'ipaddress' => $value['facts']['ipaddress'] } }
```





# Sample Snippets

Below are code samples that we have found to be helpful to refer back to. Feel free to add your own. If you do add code, please make sure the table of contents below gets updated too. If you are using VS Code, that can be done automatically on save for you if you have the [Mardown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) extension installed.

- [from Jason S on slack](#from-jason-s-on-slack)
- [PuppetDB queries in manifests](#puppetdb-queries-in-manifests)
  - [Query for nodes](#query-for-nodes)
    - [Find nodes based on facts](#find-nodes-based-on-facts)
    - [Create multiple lists of nodes from one query](#create-multiple-lists-of-nodes-from-one-query)
    - [Get a single fact from the first node in a query](#get-a-single-fact-from-the-first-node-in-a-query)
    - [Get a unique list of client IP's](#get-a-unique-list-of-client-ips)
  - [Query for resources](#query-for-resources)
    - [Find resources on a node](#find-resources-on-a-node)
    - [Get a filtered list of objects on a node](#get-a-filtered-list-of-objects-on-a-node)
- [PuppetDB queries from the command line](#puppetdb-queries-from-the-command-line)
  - [Find nodes using a group of profiles](#find-nodes-using-a-group-of-profiles)
  - [Find the subclasses of a profile that are in use](#find-the-subclasses-of-a-profile-that-are-in-use)

## PuppetDB queries in manifests

### Query for nodes

#### Find nodes based on facts

In this example the nodes returned all have the same `group`, `stage`, and `context` as the node that the query runs on and are also in the same physical (or logical) location according to the `whereami` fact.

```puppet
$node_list = puppetdb_query("inventory {
  facts.classification.group    = '${facts['classification']['group']}' and
  facts.classification.stage    = '${facts['classification']['stage']}' and
  facts.classification.function = '${facts['classification']['context']}' and
  facts.whereami                = '${facts['whereami']}'
}").map |$value| { $value['facts']['networking']['fqdn'] }
```

The `.map |$value| { $value['facts']['networking']['fqdn'] }` function appended to the end of the query converts this from an array of objects into a simple array of fqdn's.

Similarly, you can filter the list of nodes returned by the query above to only include ones that have a particular role (aka class) applied like so:

```puppet
$compilers = puppetdb_query("inventory {
  facts.classification.group    = '${facts['classification']['group']}' and
  facts.classification.stage    = '${facts['classification']['stage']}' and
  facts.classification.function = '${facts['classification']['context']}' and
  facts.whereami                = '${facts['whereami']}' and
  resources {
    type  = 'Class' and
    title = 'Role::Pe::Compiler'
  }
}")
```

In this case we do not apply the map function. A possible reason for this is that we want access to several facts from each node instead of just a single fact.

#### Create multiple lists of nodes from one query

First, the code:

```puppet
$nodes           = puppetdb_query("inventory {
  facts.classification.group = '${facts['classification']['group']}' and
  facts.classification.stage = '${facts['classification']['stage']}'
  order by certname
}")

$node_names      = $nodes.map |$value| { $value['facts']['networking']['fqdn'] }
$unique_node_ips = unique($nodes.map |$value| { $value['facts']['networking']['ip'] })
$first_node      = sort($node_names)[0]
```

The example above gets a list of nodes in the same `group` and `stage` as where the query runs, sorted by their `certname`, and saves it as `$nodes`. It then uses that single call to PuppetDB to generate three new variables:

- `$node_names`: an array of fqdn's
- `$unique_node_ips`: a array containing a deduplicated list of IP addresses
- `$first_node`: the first node in the list

Of note is that the query sorts the results for us which means the node that is list first should remain consistent over time. An example of needing to know which node is first is picking who is going to be the leader in a cluster or in a pool of servers using keepalived.

#### Get a single fact from the first node in a query

If all you really want is the IP address of the first node retuned you could reduce the code above to this:

```puppet
$first_node_ip = puppetdb_query("inventory {
  facts.classification.group = '${facts['classification']['group']}' and
  facts.classification.stage = '${facts['classification']['stage']}'
  order by certname
  limit 1
}")[0]['facts']['networking']['ip']
```

This block of code breaks down like so:

- `$first_node_ip =` tells puppet to save the result of what follows into a variable named `first_node_ip`
- `puppetdb_query("inventory {` tells puppet to use the built in `puppetdb_query` function to query the "inventory" endpoint of PuppetDB
- `facts.classification.group = '${facts['classification']['group']}'` filters the results by nodes in the same group as the node running the query
- `and` tells PuppetDB we want to combine the previous filter with another one
- `facts.classification.stage = '${facts['classification']['stage']}'` filters the results by nodes in the same stage as the node running the query
- `order by certname` tells PuppetDB to sort the results before responding to our query
- `limit 1` tells PuppetDB to only return the first result from the query. Note that if the query results had not been sorted by the previous line that this result could be different every time puppet runs.
- `}")[0]` selects the first element in the array returned by the `puppetdb_query` function. The previous line ensures that this will always be the only element in the array.
- `['facts']['networking']['ip']` selects the default IP address of the node that was returned as only piece of information to be saved

#### Get a unique list of client IP's

This example expands on the filtering shown above by first using the `.map` function to get a list of IP's and then applying the `.unique` function to that list to filter out duplicates.

```puppet
$clients = (puppetdb_query("inventory {
  facts.classification.group = '${facts['classification']['group']}' and
  facts.classification.stage = '${facts['classification']['stage']}'
}").map |$value| { $value['facts']['networking']['ip'] }).unique
```

Note when comparing this example to ones above that there is a set of parentheses that open before `puppetdb_query` and close after the `map` function. The code above could also be rewritten like so:

```puppet
$query = "inventory {
  facts.classification.group = '${facts['classification']['group']}' and
  facts.classification.stage = '${facts['classification']['stage']}'
}"

$results = puppetdb_query($query)

$all_ips = map($results) |$value| { $value['facts']['networking']['ip'] }

$unique_ips = unique($all_ips)
```

### Query for resources

#### Find resources on a node

Sometimes you need to know about the resources a host has, such as what mount points have been defined. You can get that using a query like this:

```puppet
$devices = puppetdb_query("resources {
  certname = '${trusted['certname']}' and
  type     = 'Mount'
}").map |$value| { $value['parameters']['device'] }
```

#### Get a filtered list of objects on a node

Other times you need to find resources that match some logic. An example of this is finding all the instences of the `Icinga2::Object::Service` defined type that are tagged as being a `singleton` on a node:

```puppet
$singletons = puppetdb_query("resources {
  certname = '${trusted['certname']}' and
  type     = 'Icinga2::Object::Service' and
  exported = true
}").filter |$value| { $value['parameter']['tag'] != 'singleton' }
```

The `.filter |$value| { $value['parameter']['tag'] != 'singleton' }` bit here filters out any results that do not contain a `singleton` tag.

## PuppetDB queries from the command line

If you have setup the PE client tools ([directions](https://confluence.puppetlabs.com/display/SRE/Using+PE+client+tools+with+SRE%27s+Puppet)) then you can do PuppetDB queries from your local machine too. All the examples above can be reworking the logic inside the `puppetdb_query()` function to reflect that is being run remotely. That said, its more likely that you will actually be looking for different types of info when working remotely. Below are some examples of this.

### Find nodes using a group of profiles

Say you have some profiles grouped under a parent class and you want to know if anything still uses them. You could do that like so:

```bash
$ puppet-query "inventory[certname]{ resources{ type = 'Class' and title ~ 'Profile::Forge::' } order by certname}"  |jq -r '.[].certname'
forge-aio02-petest.ops.puppetlabs.net
forgenext-jenkinsmaster01-dev.ops.puppetlabs.net
```

### Find the subclasses of a profile that are in use

Taking the example above a step farther, you can get a list of each child profile being used on each node that was returned by doing this:

```bash
for n in `puppet-query "inventory[certname]{ resources{ type = 'Class' and title ~ 'Profile::Forge::' } order by certname}"  |jq -r '.[].certname'`; do echo; echo "Checking $n:"; puppet-query "resources { certname = '$n' and type = 'Class' and (title ~ 'Profile::Forge::' or title ~ 'Role::') }" |jq -r '.[].title' |sort; done

Checking forge-aio02-petest.ops.puppetlabs.net:
Profile::Forge::Api
Profile::Forge::Rbenv
Profile::Forge::Shared
Profile::Forge::Sudo
Profile::Forge::Web
Role::Forge::Acceptance

Checking forgenext-jenkinsmaster01-dev.ops.puppetlabs.net:
Profile::Forge::Rbenv
Role::Forgenext::Jenkins_master
```

That one-liner can be expanded to this:

```bash
node_list=$(puppet-query "inventory[certname] {
  resources {
    type = 'Class' and
    title ~ 'Profile::Forge::'
  }
  order by certname
}" |jq -r '.[].certname')

for n in $(echo $node_list); do
  echo
  echo "Checking ${n}:"
  puppet-query "resources {
    certname = '${n}' and
    type = 'Class' and
    (
      title ~ 'Profile::Forge::' or
      title ~ 'Role::'
    )
  }" |jq -r '.[].title' |sort
done
```

