---
author: gene
title: ELK Stack v2 (and a correction)
tags:
- elasticsearch
- logging
- logstash
---


I’ve learned a lot since my last post. One of those things is that I was wrong… setting up Logstash on your Redis nodes isn’t such a bad idea. Another thing that I have learned is that fluentd / td-agent is not as great as I thought it was. My revised plan as depicted in the updated design below is to use Logstash Forwarder on my non-Windows nodes and send that to a Logstash instance that does nothing but stick things into a local Redis instance. Doing this also eliminates the need for my custom receiver named Sawyer. The last change noted below is that I have upped my number of Elasticsearch data nodes and Logstash indexers to 3 each. This was a direct result of load. I also like the improved distribution of shards by having more than 2 nodes in a 5×2 shard setup.

![ELK Stack v2](http://res.cloudinary.com/genebean/image/upload/v1438140559/Logging-ELK-Stack_cggirm.png)


