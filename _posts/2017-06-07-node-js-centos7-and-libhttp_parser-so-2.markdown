---
title: Node.js, CentOS7, and libhttp_parser.so.2
date: '2017-06-07 04:05:18'
---

Don't you just love it when package maintainers break you blog? Yeah, me too. Tonight I went to post an article (no, not this one) and found my site to be down. When I went to start it back up I got this:

```bash
[ghost ~]$ /usr/bin/npm start --production
node: error while loading shared libraries: libhttp_parser.so.2: cannot open shared object file: No such file or directory
```

As it turns out, the maintainer of the `nodejs-6.10.3-1.el7.x86_64` package added this to their changelog:

```
* Wed May 10 2017 Stephen Gallagher <sgallagh@redhat.com> - 1:6.10.3-1
- Update to 6.10.3 (LTS)
- https://nodejs.org/en/blog/release/v6.10.3/
- Stop using the bundled http-parser now that there is an upstream
  release with a new-enough version.
```

What they didn't do was update the their dependancies to pull in the `http-parser` package. Thus, when the update ran and the service bounced my blog stopped working. Even though the fix was a simple `yum install http-parser` this should have never happened as breaking changes like this are contrary to why people run CentOS and RHEL. 

For anyone interested, I filed a ticket for this at https://bugs.centos.org/view.php?id=13380.

**_update 24 Aug. 2017_**

It seems things have gotten worse if you are not yet on the code from CentOS 7.4 as `http-parser` has been removed from EPEL per https://bugzilla.redhat.com/show_bug.cgi?id=1481470