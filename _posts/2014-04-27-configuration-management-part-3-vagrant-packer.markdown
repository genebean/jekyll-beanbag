---
title: 'Configuration Management Part 3: Vagrant & Packer'
date: '2014-04-27 23:24:32'
tags:
- apache
- configuration-management
- devops
- puppet-me
- vagrant
---


To facilitate developing my Puppet code, the [Pro Puppet](http://amzn.to/QPzitQ) book suggests using [Vagrant](http://bit.ly/QPzpFI). Seeing as I’ve been meaning to get around to learning it for a while I decided now was the time to finally do so. The only problem is that, being a responsibly paranoid SysAdmin, I was never a fan of using a base for my work that I didn’t know the contents of. I also never liked the idea of basing my work off of something I didn’t understand (a Vagrant box) or that could go away at anytime.

**Box building time**  
 The solution to my dilemma was to learn how to use Vagrant and to make my own base boxes for it. Their site does a good job of listing the minimum specs and Puppet Labs publishes the [recipes](http://bit.ly/QPAf5g) for their base boxes that are built using [Veewee](http://bit.ly/QPAoFN) on GitHub. Between these two resources I was able to figure most stuff out and built a CentOS 6 vm that was to be my base. I was then able to use another tool called [Packer](http://bit.ly/QPBnWy) to [reference the VMX file](http://www.packer.io/docs/builders/vmware-vmx.html) and build a box from it.

**I have a box, now what?**  
 Once I built this first iteration of my box I setup an account on Vagrant Cloud, setup space on [my personal server](http://bit.ly/QPBJMV) to host the boxes, and published my VMware Fusion box. The problem was that I couldn’t publish my Packer template because it was dependent on a custom vm.

**Packer to the Rescue, Again **  
 I then dove into Packer a bit more and, thanks to [another resource](http://bit.ly/QPFy4B) found on GitHub, was able to take what I learned from my first box and produce base boxes for both VirtualBox & VMware Fusion using a fairly simple template file, some shell scripts, an ISO, and a kickstart file. These new boxes are exactly what I was aiming for. I’ve [published the template](http://bit.ly/QPFNg4) on GitHub and, after a bit more testing, will be publishing the boxes on [my Vagrant Cloud account](http://bit.ly/QPFX7g).

**Next up:**  
 Once those boxes are vetted I’ll be making versions with Puppet pre-installed so that I can get back to the book.


