---
title: Gentoo & MySQL Binary Logging
date: '2013-04-07 23:23:27'
tags:
- gentoo
- mysql
---


So, I learned today that the root cause of my site issues was that Gentoo apparently decided to enable binary logging by default yet did not have a max size or may days set in my.cnf like other distros do so, as a result, I had MANY gigabytes of logs which filled up /. Lesson learned. Thanks to Zabbix I knew about the issue straight away and was able to minimize my downtime.


