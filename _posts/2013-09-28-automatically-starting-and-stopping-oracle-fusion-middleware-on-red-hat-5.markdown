---
title: Automatically Starting and Stopping Oracle Fusion Middleware on Red Hat 5
date: '2013-09-28 17:58:34'
tags:
- opensource
- oracle
- red-hat
---


At work we utilize Oracle Fusion Middleware on Red Hat 5.8.  As the primary systems administrator for the servers running FMW, I always found it to be a real pain that something as simple as a reboot required me to involve the app admin.  Instead of just being annoyed I got with that app admin to learn how the services were started and stopped and then wrote a set of SysV init scripts to automate that process.  These scripts seem to be reliable now so I have released the code on BitBucket at [https://bitbucket.org/genebean/oracle-fmw-sysv-init](https://bitbucket.org/genebean/oracle-fmw-sysv-init).  These scripts cover all the components used when running Ellucian’s Internet Native Banner and Self Service Banner.


