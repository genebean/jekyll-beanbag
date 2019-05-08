---
title: Upgrade to Puppet 5
image: ''
date: '2017-07-15 03:34:46'
author: Jake Spain
tags:
- puppet
---

Today I successfully upgraded our Puppet Master from Puppet 4.x (puppetserver 2.7.2) to Puppet 5 (puppetserver 5.0.0). It was wildly helpful to go through the entire upgrade process and perform LOTS of testing and troubleshooting with the [Vagrant Puppet Environmet](https://github.com/genebean/vagrant-puppet-environment), which is basically an exact replica of my production environment. This is an all-in-one Open Source Puppet setup and, once the next release is out, I would highly recommend for testing!

The problems I had below were no fault of the Puppet upgrade itself, but actually by module(s) not yet adapted for 5.x. We use a combination of theforeman and puppetlabs modules to manage the installation of puppetserver, puppetdb, and the agent.

####Problem #1####
My first issue was a classic case of **RTFM**. As the [doc](https://docs.puppet.com/puppetdb/5.0/) clearly states Postgres 9.6 required. It turns out that 9.4 != 9.6. I received an error stating this fact in the PuppetDB log when attempting to start. So for those needing to upgrade a simple change to the postgres user and `pg_dumpall -f /tmp/pg_dumpall94`, then upgrade Postgresql and `psql -f /tmp/pg_dumpall94`. I performed incremental upgrades from 9.4 -> 9.5 -> 9.6 _just_ to be extra safe.

####Problem #2####
The second problem was I got stumped on an error about the new metrics-webservice feature that was causing puppetserver not to start. I was pleasantly surprised when I submitted Puppet ticket [SERVER-1876](https://tickets.puppetlabs.com/browse/SERVER-1876) and someone replied within two hours on a Saturday. Which then fixed the issues, but also pointed me in the right direction and found that theforeman-puppet module decided to whack a line in `/etc/puppetlabs/puppetserver/conf.d/web-routes.conf`.

I noticed they had already started working on the fixes on the master branches for these modules, so I ran the vagrant environment on that until they cut a release.

**NOTE**: Even though theforeman-puppet module 8.0.0 is now comatible, it looks like theforeman-installer itself will not be until version 1.16, so this will only present a problem when installing from scratch. See the Puppet ticket [SERVER-1876](https://tickets.puppetlabs.com/browse/SERVER-1876) to fix the issue yourself or just run the nightly release which has already been fixed.

####Problem #3####
Once that was all behind me the only remaining issue was a failed puppet run on the node running PuppetDB, which was caused by an incompatibility between the puppetdb and postgresql modules. See [PDB-3587](https://tickets.puppetlabs.com/browse/PDB-3587) for details. Other than that it was functioning just fine.

####The Actual Upgrade####
Once I updated to the newly released versions of theforeman-puppet 8.0.0, puppetlabs-puppetdb 6.0.0, and puppetlabs-postgresql 5.0.0, then a Puppet agent run on the master node and puppetdb node ran like a charm in test!

All that said and done, after updating the modules on production, upgrading basically as simple as `yum upgrade` and `puppet agent -t`. Really. Im not kidding, that was it.
![partyparrot](/content/images/2017/07/partyparrot-1.gif)