---
ID: 149
post_title: ELK Stack v2 (and a correction)
author: GeneBean
post_date: 2015-07-20 23:31:12
post_excerpt: ""
layout: post
permalink: >
  http://beanbag.technicalissues.us/2015/07/elk-stack-v2-and-a-correction/
published: true
---
I've learned a lot since my last post. One of those things is that I was wrong... setting up Logstash on your Redis nodes isn't such a bad idea. Another thing that I have learned is that fluentd / td-agent is not as great as I thought it was. My revised plan as depicted in the updated design below is to use Logstash Forwarder on my non-Windows nodes and<!--more--> send that to a Logstash instance that does nothing but stick things into a local Redis instance. Doing this also eliminates the need for my custom receiver named Sawyer. The last change noted below is that I have upped my number of Elasticsearch data nodes and Logstash indexers to 3 each. This was a direct result of load. I also like the improved distribution of shards by having more than 2 nodes in a 5x2 shard setup.

<a href="http://res.cloudinary.com/genebean/image/upload/v1438140559/Logging-ELK-Stack_cggirm.png"><img class="aligncenter size-full wp-image-150" src="http://res.cloudinary.com/genebean/image/upload/v1438140559/Logging-ELK-Stack_cggirm.png" alt="ELK Stack v2" width="2550" height="5809" /></a>