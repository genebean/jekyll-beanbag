---
title: Using Oracle Wallet with Wildcard Certificates
date: '2013-02-05 14:55:56'
tags:
- oracle
- ssl
---


Do you have to use Oracle Wallet as part of Fusion Middleware? Do you also have a wildcard SSL certificate?  If so, then this tutorial is for you.  This tutorial is the result of trying to make a new install of Internet Native Banner (INB) play nicely with our wildcard certs so that if we change the hostname of the system or clone the virtual machine SSL does not break or require adjustment.

To start things off, let’s establish a couple of conventions that will be used in the tutorial.  First, I will use a couple of environment variables throughout:

- $OHS_INSTANCE_HOME is the Oracle HTTP Server’s home.  If your application happens to be INB then the directory listing will look something like this: 

```bash
[genebean ~]$ sudo ls -l $FMW_HOME
total 780
drwx------ 3 oracle oinstall 4096 Sep 24 14:11 auditlogs
drwx------ 2 oracle oinstall 4096 Sep 24 14:11 bin
drwx------ 11 oracle oinstall 4096 Sep 24 14:44 config
drwx------ 3 oracle oinstall 4096 Sep 24 14:11 diagnostics
-rw-r----- 1 oracle oinstall 682905 Feb 1 13:56 dms.log
drwx------ 3 oracle oinstall 4096 Sep 24 14:44 EMAGENT
drwx------ 3 oracle oinstall 4096 Sep 24 14:11 FormsComponent
drwx------ 4 oracle oinstall 4096 Sep 24 14:11 FRComponent
drwx------ 3 oracle oinstall 4096 Sep 24 14:11 OHS
drwx------ 6 oracle oinstall 4096 Sep 24 14:11 reports
-rw-r----- 1 oracle oinstall 327 Feb 1 14:13 reports.log
drwx------ 3 oracle oinstall 4096 Sep 24 14:13 ReportsServerComponent
drwx------ 3 oracle oinstall 4096 Sep 24 14:11 ReportsToolsComponent
drwx------ 2 oracle oinstall 4096 Sep 24 14:11 tmp
```

- $FMW_BASE is where Fusion Middleware Base.  Of particular notability here is that this is where your bin folder is located.  Again, for INB, here is the directory listing.

```bash
[genebean ~]$sudo ls -l $FMW_BASE
total 716
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:21 admin
drwxr-x--- 2 oracle oinstall 4096 Sep 12 13:22 adminserver_registration
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 Apache
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 archives
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:22 asoneofftool
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:24 assistants
drwxr-xr-x 2 oracle oinstall 12288 Sep 12 13:54 bin
drwxr-x--- 6 oracle oinstall 4096 Sep 12 13:22 browser
drwxr-x--- 7 oracle oinstall 4096 Sep 12 13:37 ccr
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 cdata
drwxr-x--- 5 oracle oinstall 4096 Sep 12 13:29 cfgtoollogs
drwxr-x--- 6 oracle oinstall 4096 Sep 12 13:22 chgip
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:35 clone
drwxr-x--- 9 oracle oinstall 4096 Sep 12 13:35 common
drwxr-x--- 2 oracle oinstall 4096 Sep 12 13:24 config
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:22 crs
drwxr-x--- 7 oracle oinstall 4096 Sep 12 13:23 css
drwxr-x--- 2 oracle oinstall 4096 Sep 12 13:22 dbs
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:21 diagnostics
drwxr-x--- 9 oracle oinstall 4096 Sep 12 13:21 discoverer
drwxr-x--- 12 oracle oinstall 4096 Sep 12 13:35 doc
-rw-r----- 1 oracle oinstall 430 Apr 7 2008 dummy.ic.linux.txt
-rw-r----- 1 oracle oinstall 412 Apr 7 2008 dummy.ic.txt
-rw-r----- 1 oracle oinstall 415 Apr 7 2008 dummy.ssl.txt
drwxrwxr-x 2 oracle oinstall 4096 Sep 12 13:24 EMStage
drwxr-x--- 14 oracle oinstall 4096 Sep 12 13:23 forms
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:23 frcommon
drwxr-x--- 5 oracle oinstall 4096 Sep 12 13:22 guicommon
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 has
drwxr-x--- 6 oracle oinstall 4096 Sep 24 14:49 install
-rw-r----- 1 oracle oinstall 37 Sep 12 13:21 install.platform
drwxr-x--- 2 oracle oinstall 4096 Sep 12 13:22 instantclient
drwxrwx--- 14 oracle oinstall 4096 Sep 12 13:37 inventory
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:27 j2ee
drwxr-x--- 6 oracle oinstall 4096 Sep 12 13:23 javavm
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 jdbc
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:22 jdev
drwxr-xr-x 6 oracle oinstall 4096 Sep 12 13:35 jdk
drwxr-x--- 2 oracle oinstall 4096 Sep 12 13:35 jlib
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:22 jpub
drwxr-x--- 12 oracle oinstall 4096 Sep 12 13:24 ldap
drwxr-xr-x 4 oracle oinstall 20480 Sep 12 14:05 lib
drwxr-x--- 3 oracle oinstall 4096 Sep 12 14:05 lib32
drwxr-x--- 2 oracle oinstall 4096 Sep 12 13:24 mesg
drwxr-x--- 40 oracle oinstall 4096 Sep 12 13:36 modules
drwxr-x--- 12 oracle oinstall 4096 Sep 12 13:24 network
drwxr-x--- 5 oracle oinstall 4096 Sep 12 13:23 nls
drwxr-x--- 21 oracle oinstall 4096 Sep 12 13:24 ohs
drwxr-x--- 2 oracle oinstall 4096 Sep 12 13:36 oneoffpatches
drwxr-x--- 9 oracle oinstall 4096 Sep 12 14:20 OPatch
drwxr-x--- 7 oracle oinstall 4096 Sep 12 13:24 opmn
-rwx------ 1 oracle oinstall 475 Sep 24 13:57 oracleRoot.sh
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:22 oracore
-rw-r----- 1 oracle oinstall 65 Sep 12 10:28 oraInst.loc
drwxr-x--- 5 oracle oinstall 4096 Sep 12 13:23 ord
drwxr-x--- 6 oracle oinstall 4096 Sep 12 13:37 oui
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:24 owm
drwxr-xr-x 5 oracle oinstall 4096 Sep 12 13:24 perl
drwxr-x--- 6 oracle oinstall 4096 Sep 12 13:24 plsql
drwxr-x--- 9 oracle oinstall 4096 Sep 12 13:23 portal
drwxr-x--- 9 oracle oinstall 4096 Sep 12 13:23 precomp
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:22 procbuilder
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:23 racg
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:35 rcu
drwxr-x--- 6 oracle oinstall 4096 Sep 12 13:35 rda
drwxr-x--- 10 oracle oinstall 4096 Sep 12 13:23 rdbms
drwxr-x--- 5 oracle oinstall 4096 Sep 12 13:23 relnotes
drwxr-x--- 16 oracle oinstall 4096 Sep 12 13:22 reports
-rwxr-x--- 1 oracle oinstall 7651 Sep 12 13:24 root.sh
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:22 slax
drwxr-x--- 14 oracle oinstall 4096 Sep 12 13:22 sqldeveloper
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:22 sqlj
drwxr-x--- 8 oracle oinstall 4096 Sep 12 13:24 sqlplus
drwxr-x--- 7 oracle oinstall 4096 Sep 12 13:23 srvm
drwxr-x--- 13 oracle oinstall 4096 Sep 24 14:44 sysman
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 tg4ifmx
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 tg4ingr
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 tg4sybs
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:23 tg4tera
drwxr-x--- 4 oracle oinstall 4096 Sep 12 13:22 tools
drwxr-x--- 6 oracle oinstall 4096 Sep 12 13:24 upgrade
drwxr-x--- 10 oracle oinstall 4096 Sep 12 13:24 webcache
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:21 webcenter
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:22 webservices
drwxr-x--- 3 oracle oinstall 4096 Sep 12 13:22 wwg
drwxr-x--- 6 oracle oinstall 4096 Sep 12 13:24 xdk
```

Secondly, this was tested with utilizing wildcard certificates from GoDaddy.  If you are using certificates from elsewhere then use your signing authority’s chain file / intermediate certificate(s) in place of gd_bundle.crt below.


##  SSL Certificate Creation / Installation

1. Go to [https://www.sslshopper.com/ssl-converter.html](https://www.sslshopper.com/ssl-converter.html) and create a PFX cert from the standard wildcard.crt file, the gd_bundle.crt file, and the privatekey.key file. 1. A password must be set and it must be complex.  The minimum length is 8 alphanumeric characters.  Details about these requirements can be found at [http://docs.oracle.com/cd/B10501_01/network.920/a96573/asowalet.htm](http://docs.oracle.com/cd/B10501_01/network.920/a96573/asowalet.htm).
2. If your password does not conform to the complexity requirements then you will get an error stating that your “password is incorrect” when you try to open it with Oracle Wallet Manager.
3. Download the cert and rename it to *ewallet.p12*. The name is critical here as Oracle Wallet Manager will not see it otherwise.
4. Make a directory for the wallet files in $OHS_INSTANCE_HOME/config/OHS/ohs1/keystores/. I would suggest that you name the directory based on your domain name since the certificate has a generic name. 1. ex: A certificate for *.technicalissues.us would result in a directory named technicalissues_us
5. Assuming you are working on a command line only system, SFTP the certificate into this new directory and ensure it’s permissions and ownership match the parent directory.
6. Run $FMW_BASE/bin/owm 1. Select Wallet → Open
7. Browse to the wallet directory under $OHS_INSTANCE_HOME/config/OHS/ohs1/keystores/
8. Enter the password when prompted
9. Click on Wallet in the Menu and mark the checkbox against Auto Login
10. Save the wallet


## Making the webserver use the wallet

**In Web Tier → ohs1**

1. Go to Oracle HTTP Server → Administration → Virtual Host
2. Choose *.443 and Configure (SSL)
3. Check Enable SSL
4. Under Server Wallet Name choose the wallet from step 3 in the previous section.
5. Select Oracle HTTP Server → Control → Restart


## Wrapping up

At this point, you should be able to connect  to you web application via HTTPS without any SSL warning from your browser, assuming your certificate is from a trusted provider.

Lastly, I must give credit where it is due.  Much of the information in this tutorial is adapted from http://fusionapplications-ateam.blogspot.com/2012/08/using-san-certificates-with-oracle-http.html.  Without the info found there, this post would not have come to fruition.

**Edit:** The above link is now dead.  I have been told that this is a good replacement to it though: [http://www.ateam-oracle.com/using-san-certificates-with-oracle-http-server-11g](http://www.ateam-oracle.com/using-san-certificates-with-oracle-http-server-11g)


