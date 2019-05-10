---
author: gene
title: Vagrant, Fusion, & DHCP Oddities
tags:
- vagrant
---


I’ve had some random weirdness that I thought was related to Vagrant’s VMware Fusion provider until I turned on debugging tonight. As it turns out, Fusion had decided at some point in the past to start storing it’s DHCP leases in vmnet-dhcpd-vmnet8.leases~ instead of vmnet-dhcpd-vmnet8.leases. The same was true for vmnet1 too. After quitting Fusion and running ‘sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli –stop’ I removed vmnet-dhcpd-vmnet* so that all the leases would be reset. After that I reran ‘vagrant up’ and (finally) things worked as expected.


