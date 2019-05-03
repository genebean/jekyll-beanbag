---
title: Hyper-V, CentOS 6.5 kernel panic, and 7 long hours
date: '2014-05-28 22:41:32'
tags:
- centos
- hyper-v
- linux
---


In hopes of it helping someone else not spend hours of work like I just did here is my lesson-learned from my first day of using Windows Server 2012 r2 Hyper-V.


## Lesson 1:

Look at the defaults and read the descriptions… don’t just try and set stuff like you do in VMware…


## Lesson 2:

It seems that “vga=791″ being added as a kernel parameter causes a kernel panic on Hyper-V whereas it works great on VMware and Virtualbox… the interesting thing is that, unlike the other two hypervisors, I get a decent size window by default with Hyper-V so I don’t even really need this option (yay).  I just wish I had known this before spending 7 hours hunting why I was getting a kernel panic after doing a kickstart install.


## Wrapup:

So far, things look good.  The learning curve has been very minimal and the install was dead-simple.  I am actually looking forward to getting some more time with Hyper-V.


