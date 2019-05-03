---
title: Updating to Puppet 4, part 2
date: '2017-01-28 19:36:56'
---

#### **_Four repos become one..._**

When I last created a full Puppet environment "Roles & Profiles" were the _new_ way to do things. [Gary Larizza][gary] was posting articles that talked all about how each of these should be in their own repository and how we should use r10k and hiera and how each of them should also have a repo. What that meant was that concerns were well separated but it also made for a rather complex environment.

Since then we have all learned a lot and have come up with what I can confidently say is a vastly improved workflow: the Control Repo. After reading [the official docs][pe control] I still had questions so I decided to see if Gary had talked about it and of course he had. He actually has two articles on the subject that helped me solidify how to move forward:

* [Workflows Evolved: Even Besterer Practices][evolved]
* [Roles and Profiles in a Control Repo?][rpcr]

The end result of all of this is that I've been able to move from having four repos (roles, profiles, hiera, & environments / r10k / Puppetfile) to just one: my control repo. 

#### The Result

The results of this are starting to come to come together. I've cloned Puppet's template repo and created [genebean/control-repo][mycr]. Its still very much a work in progress but its gradually taking all the settings and classifications that I was doing in scripts and with `puppet apply` in Vagrant and making them more like a finalized setup.

#### Next Up

Next is to transfer over my webhook receiver's code from my current Puppet Master to my new setup and to adjust it to play nice with the control repo. After that I think it will be time to start extracting the PostgreSQL databases used by PuppetDB and Foreman onto their own node. This will allow me to implement an active/standby cluster a la the one [Google has a solution guide for][goopg]. After the DB is redundant I can then go about adding redundancy to the server node that houses all the applications (Puppet Server, Foreman, & PuppetDB).


[evolved]: http://garylarizza.com/blog/2015/11/16/workflows-evolved-even-besterer-practices/
[gary]: http://garylarizza.com/
[goopg]: https://cloud.google.com/solutions/setup-postgres-hot-standby
[mycr]: https://github.com/genebean/control-repo
[pe control]: https://docs.puppet.com/pe/latest/cmgmt_control_repo.html
[rpcr]:http://garylarizza.com/blog/2017/01/17/roles-and-profiles-in-a-control-repo/