---
author: gene
title: 'Foreman: Too Much Voodoo'
tags:
- configuration-management
- git
- puppet
---


I finally got around to setting up [Foreman](http://bit.ly/1eXLC65) at work and managing my first node with it.  After digging around I found that I felt really boxed in using this setup because so much of the work is done behind the scenes in some magical way.  One of my main goals is to facilitate the concept of infrastructure as code and, like my code, track changes via git and store them in our [GitLab](http://bit.ly/1eXPDY8) instance.  The Foreman, as best I can tell, takes and hides <span style="text-decoration: underline">everything</span> it does inside a database which prevents me from being able to apply any version control to it’s settings.  This is an unforeseen and unfortunate reality because the developers have made a really good looking product that can do a lot of really cool things.  For me though, this is too much voodoo at this early of a stage of us doing configuration management and I think I’m going to back out my install and start over with a different approach that defines nodes in pain text .pp  files.  I’m sure I’ll take advantage of pulling in data from some external source like [Hiera](http://bit.ly/1eXM6cm) and / or other systems we have to help make decisions dynamically but I don’t think I want the configs themselves in a db… who knows; guess I’ll try it out and see.

On a brighter note, I imagine that I will eventually be able to find a good balance between being able to track things with git and being able to utilize [Foreman’s Smart Proxy features](http://bit.ly/1eXNlbq) to simplify deployments of new systems in my VMware environment.  I love the idea of being able to automate an entire deployment workflow that includes all of the following (and more):

1. creating the VMware virtual machine
2. creating a DHCP reservation
3. creating an A record in DNS
4. installing the OS
5. joining the domain
6. installing and configuring applications
7. configuring the firewall on the host
8. setting access rights
9. running a security scan with Nessus
10. configuring our F5 LTM if needed
11. configuring the perimeter firewall if needed

 


