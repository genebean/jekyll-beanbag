---
author: gene
title: Zabbix 3.2 is WAY more efficient!
---

Recently our Oracle DBA hit me up and said that all of a sudden some of his servers were showing a load average of `0.00, 0.00, 0.00`. To diagnose this I started looking at our Zabbix dashboard to see when the load dropped off. I noticed it was on March the 3rd so I checked a second host and found that it also dropped off on the same day... *interesting*. 

![Graph showing drop in load](/content/images/2017/03/load-drop.png)

This made me think it might be OS-related so I decided to take a look at `/var/log/yum.log` to see if anything was installed or updated around the mystical date found in the graphs. To my surprise, not only was there an entry for that date but it was for the Zabbix agent. A moment or two later I realized that that was when we were doing our upgrade of agents from 2.4 to 3.2. At this point I was more than a little surprised and rather skeptical so I went to each and every host that he said had the zeroed-out load averages and found exactly the same thing. I then went onto one host that did not have all zeros and found that even though the agent had been upgraded that the service had not been restarted. Naturally, I bounced the service and was pleasantly surprised to see that the load dropped off.

To get a bit of imperial evidence for my case I worked with another one of our sysadmins to find a box that had not yet been upgraded. He then went through the process of upgrading the Zabbix agent from version 2.4.8 to 3.2.4. About a week later he pulled the load graph and found that our hypothesis was spot on: the new agent makes a measurable difference.

![Image showing before and after the upgrade](/content/images/2017/05/pre-post-upgrade-load.jpeg)

What is really interesting about this to me besides the geekiness of it is what it could mean on a larger scale in a data center or somewhere like AWS. With the load dropping in such a noticeable way I don't think its a stretch at all to say that it makes the machines use less power and fewer CPU cycles. In a data center that could equate to a lower bill from the power company both because of the explicit drop in usage and because of the reduced heat generation which means less money spent on cooling. In AWS fewer CPU cycles can equate to a lower bill.

Many thanks to Joe for the initial info and to Matt for helping me gather data.