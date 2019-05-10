---
author: gene
title: Vagrant, Veewee, & Me (part 1)
tags:
- centos
- linux
- opensource
- puppet
- vagrant
---


I have toyed with the idea of diving into [Vagrant](http://www.vagrantup.com/) for a while now and, tonight, decided it was time.  I decided to be different and RTFM… this left me with two big questions: where can I get “boxes” from and how can I easily make my own?  After a little Googling I discovered that [Puppet Labs](http://puppetlabs.com) provides a small library of [the boxes they use](http://puppet-vagrant-boxes.puppetlabs.com/) internally.  On their page I also found the answer to my second question of how to make my own: [Veewee](http://github.com/jedi4ever/veewee).  It seems I have a bit of setup to do before I can start using Veewee but I think it will be worth it.  My plan is to bring up a base [CentOS](http://www.centos.org) 6.4 x86_64 box and then make [a Vagrantfile that uses Puppet](http://docs.vagrantup.com/v2/provisioning/puppet_apply.html) to configure it for building RPM’s in.  Ideally, I will start including this Vagrantfile with the source of any RPM I publish so that building a new one is easy-peasy.


