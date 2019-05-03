---
title: 'Configuration Management Part 2: puppetlabs-apache & puppet-lint'
date: '2014-04-23 22:54:34'
tags:
- apache
- configuration-management
- puppet
- puppet-me
---


Today was a good day. I installed puppet-lint and ran it against a custom module I’m writing for my first node and found lots of issues that it was kind enough to tell me exactly how to resolve. I then got down to using my first module from Puppet Forge: [puppetlabs-apache](http://bit.ly/1nq94vg)  Installing it was a piece of cake but understanding how to use it took a bit of trial and error.

**My First Puppetized Apache Server **  
 One of the things my first node needs is an Apache install that can serve CGI files via httpand https… seems simple enough, right? To facilitate this I see from the module’s docs that it makes a default vhost for httpand, optionally, can do so for SSL too. I took at the default values for the module’s parameters and decided they weren’t going to cut it so I called the apache class and told it not to make a default site. That was simple since the entire code block was I  the docs. Then I had to figure out how to call apache::vhost in my node definition.

Creating the vhost was a little more complicated but made perfect sense after a while & several puppet-lint runs. Once I crossed that bridge I then proceed to take all the required setting from the install docs of what’s going on the node and added them to a newly defined default vhost and, also, to a new default SSL vhost. Again, trial and error and puppet-lint but, in the end, all is well and I am now serving a placeholder “default.html” as the index in my Puppet-created document root.

**Up Next**  
 Tonight I’m reading up on Puppet environments and am about to read about “Developing Puppet with Vagrant” in *Pro Puppet, second edition*. Tomorrow I plan to actually deploy the website’s vendor provided content and associated settings via Puppet…


