---
author: gene
---

Better than two years ago I created a multi-node Vagrant setup based around a three node Puppet environment with boxes for:

1. Foreman acting as a CA, report viewer, and ENC
2. PuppetDB
3. A Puppet master with r10k 

The environment also has a client node to test against.

At the time I built all this Puppet 3.x was as the latest version. Fast forward to January 2017 and Puppet 3 has been end-of-life'd, Puppet is on version 4.8, Puppet Server is on version 2.7, and control repos are a thing so I figured it was time to update my stuff.

So far I have revised my setup so that Foreman is not only the CA, report viewer, and ENC but also the Puppet master. PuppetDB is also on the same server and everything is running the latest versions. R10k is also part of this setup.

Both Foreman's web interface and Puppet Server are fronted by a node running HAProxy that acts as a layer 4 load balancer. Adding this into mix allows me to model using a load balancer in production as a service proxy and lays the ground work for creating a HA environment.

**Up Next**

The next step is to finish moving settings from my Vagrantfile to my sample control repo. Once that's done I'm planning on moving Postgres onto a separate node and point both Foreman and PuppetDB at it. If that goes well then it will be time to create an active / standby cluster for Postgres. Assuming I survive this far it'll then be time to tackle making both Foreman and Puppet Server highly available. As to whether they will be active / active or active / standby is yet to be determined.