---
author: gene
title: 'Configuration Management Part 1: The Restart'
tags:
- configuration-management
- git
- puppet
---


As mentioned in my [last post](http://bit.ly/1eXR5cQ), I’ve decided to start over on my journey to doing configuration management in an environment where we treat our infrastructure as code. Today I kicked things off by setting up a new Puppet Master on CentOS 6.5. Once my usual setup was applied to the system via a PXE boot & Kickstart installed Git and the puppetmaster package and was off.

**Version Control**  
 One of my main goals is to track everything in Git so my first task was to change the group ownership of /etc/puppet to my puppetadmins group and give them write access. Then I needed to initialize a repo in that directly, tell Git that it’s a shared repository so other admins can work in it too, and tell Git to ignore the modules folder. I then applied the group permissions to everything inside the folder, did setgid on modules & manifests, and lastly I did a setfacl on modules & manifests so that us admins would retain rwx on all files and folders. Lastly I cloned my first module from our GitLab instance into a folder under modules.

**Master Configs**  
 This was a bit easier… I just made a node definition in site.pp and set my certname & dns_alt_names.

**Today’s Wrapup**  
 With very little work, some time reading Pro Puppet, and some trial and error I now have a working system via Puppet open source that’s tracked in Git.

**Next Time**  
 Next up is pulling in Puppet Labs Apache module and using it to enhance my new master and a node.


