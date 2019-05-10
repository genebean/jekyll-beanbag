---
author: gene
---

##### *Hooked and Proxied*

When I left off last time a webhook receiver was needed... well, its finished and published to [Puppet Forge] as [genebean/puppetmaster_webhook]. The module creates a custom [Sinatra] application and installs it along with [RVM]. The end result is that you can post messages from GitHub or GitLab and have it deploy the corresponding repository's branch or environment.

While I was setting all this up I also decided to front everything with HAProxy so that I could simulate being behind a load balancer immediately and to prepare for the eventual high availability setup that is my end goal. As of today I have it so that all nodes talk to the Puppet master by way of the proxy. [Foreman] and my webhook receiver are also being fronted by the proxy.

##### *Round 1 Complete*

The first round of the project was to get everything up to date and using Puppet 4. That part is complete and posted to GitHub at https://github.com/genebean/vagrant-puppet-environment. To quote the description in the repo's readme

> This repo has everything needed to setup a Puppet environment in Vagrant. It includes all the components that make up a complete system including load balancer, Puppet Server, PuppetDB, Foreman, r10k, and PostgreSQL. It also
pulls down a sample [control repo] for Hiera, roles, and profiles.

Having achieved this I can comfortably say that round one is complete which must mean that its time for round two.

##### *Round 2 Coming Up*

Round two is starting off with pulling PostgreSQL out onto its own server and then making that server highly available. This will lay the ground work for making the rest of the stack highly available. Based on some research, including a great article entitled *[Journey to High Availability]*, it looks like the first step after the database will be to implement Memcached by way of [theforeman/foreman_memcache] so that [Foreman] will work correctly when clustered. Having said that, things tend to change as you are learning how to cluster an application so I don't think I'll speculate any farther down the road yet.


[control repo]:https://github.com/genebean/control-repo
[Foreman]:https://theforeman.org/
[genebean/puppetmaster_webhook]:https://forge.puppet.com/genebean/puppetmaster_webhook
[Journey to High Availability]:https://theforeman.org/2015/12/journey_to_high_availability.html
[Puppet Forge]:https://forge.puppet.com/
[RVM]:https://rvm.io/
[Sinatra]:http://www.sinatrarb.com/
[theforeman/foreman_memcache]:https://github.com/theforeman/foreman_memcache