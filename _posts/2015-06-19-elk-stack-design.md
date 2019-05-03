---
ID: 136
post_title: ELK Stack Design
author: GeneBean
post_date: 2015-06-19 23:56:48
post_excerpt: ""

permalink: >
  http://beanbag.technicalissues.us/2015/06/elk-stack-design/
published: true
---
I've been working on a new logging system based around <a href="https://www.elastic.co/products/elasticsearch" target="_blank">Elasticsearch</a>, <a href="https://www.elastic.co/products/logstash" target="_blank">Logstash</a>, and <a href="https://www.elastic.co/products/kibana" target="_blank">Kibana</a>. One of my biggest challenges was that all the recommended designs I found said that logs should go from a shipper to <a href="http://redis.io" target="_blank">Redis</a>. The problems with this are twofold:
<ol>
	<li>Logstash doesn't seem like a good fit for Windows. The biggest issues are that it relies on Java which isn't something that is very sellable to any Windows admin that I know. The other is that it simply didn't work reliably in my testing. The <a title="Logstash 1.5.0 GA release notes" href="https://www.elastic.co/blog/logstash-1-5-0-ga-released" target="_blank">1.4.x series had performance issues</a> and the copy of 1.5.1 I just tried on Windows 7 is throwing
<code>Windows Event Log error: Invoke of: NextEvent
Source: SWbemEventSource
Description: Timed out</code>
errors under even the simplest of tests. Unlike other tools it also requires specifying each Event Log that you want to monitor individually as opposed to being able to just grab them all.</li>
	<li>Not everything can have an agent on it which means that I needed a way to pipe syslog into Redis</li>
</ol>
The Windows issues were solved by utilizing <a title="NXLog Community Edition" href="http://nxlog.org/products/nxlog-community-edition" target="_blank">NXLog</a> as a log shipper but that introduced another problem: NXLog doesn't have a Redis output. On the plus side though, NXLog seems to be the gold standard when it comes to getting at Event Log data and it can <a href="http://nxlog.org/docs/nxlog-ce/nxlog-reference-manual.html#xm_json" target="_blank">convert the log entries into JSON</a>. This just leaves finding a way to add the Logstash-specific information to the message and then a way to insert that message into Redis.<!--more--> As it turns out, this issue is not that different from the one of piping syslog into Redis. After looking around for several days I found that there weren't really any good solutions to this other than standing up a separate Logstash server. This seemed like a huge waste of resources and also proved to be problematic when trying to start out with all services on a single node. These needs precipitated me writing <a title="Sawyer on GitHub" href="https://github.com/genebean/sawyer" target="_blank">Sawyer</a>. Sawyer is a <a href="https://nodejs.org/" target="_blank">Node.js</a> application that accepts these inputs, massages them accordingly, and then inserts them into Redis for Logstash to pick up.
<h1>Infrastructure: Take 1</h1>
With Sawyer getting syslog data and JSON from NXLog (or other sources) into Redis I could now focus on really building out my infrastructure. As eluded to earlier, I started out with everything on one box. This included all of the ELK stack, two Redis instances, Sawyer, and Apache. Apache was setup to protect all of this by way of Apache's <a title="Apache mod_authnz_ldap docs" href="http://httpd.apache.org/docs/2.2/mod/mod_authnz_ldap.html" target="_blank">mod_authnz_ldap</a> and basic auth. This allowed some rudimentary access control via HTTP Basic Auth backed by Active Directory. Shipping our <a title="ISC DHCP" href="https://www.isc.org/downloads/dhcp/" target="_blank">ISC DHCP</a> logs, firewall logs, all logs from our domain controllers, all logs from our Windows RADIUS servers (NPS Servers), and the Apache logs from <a title="Reflector: UWG's Software Mirror" href="http://reflector.westga.edu" target="_blank">the software repository we run</a> quickly caused this setup to fall over.
<h1>Infrastructure: Take 2</h1>
Since one node wasn't cutting it I decided it was time to scale the entire system out based on some recommendations from some very helpful people at <a title="Elastic website" href="https://www.elastic.co" target="_blank">Elastic</a>. Below is a diagram of the setup I am currently implementing:

[caption id="attachment_144" align="aligncenter" width="2550"]<a href="http://res.cloudinary.com/genebean/image/upload/v1438140565/ELK-Stack_s3pc7v.png"><img class="wp-image-144 size-full" src="http://res.cloudinary.com/genebean/image/upload/v1438140565/ELK-Stack_s3pc7v.png" alt="Infrastructure Diagram" width="2550" height="5417" /></a> Click for a much larger version.[/caption]

This design accomplishes a few different things:
<ul>
	<li>more processing capacity for both Logstash and Elasticsearch</li>
	<li>redundancy in data storage</li>
	<li>redundant and load balanced Redis nodes</li>
	<li>dedicated Elasticsearch masters</li>
</ul>
Each log source in this setup, be it a server with an agent of some kind or a device shipping raw syslog data, is configured to point at a single virtual IP. That VIP resolves to a HA pair of F5 load balancers that route the traffic to a pair of nodes running Redis and Sawyer. A pair of Logstash servers each pull from both Redis nodes, index the data, and output it to an Elasticsearch cluster. Kibana is setup on the same host as an Elasticsearch query node which allows it to pull data from the entire cluster instead of just one of the data nodes.
<h2>Licensing and Additional Features</h2>
<a title="Elastic subsciptions" href="https://www.elastic.co/subscriptions" target="_blank">Elastic's Gold Subscription</a> provides support plus access to some additional products including Shield, Marvel, and Watcher. The subscription is per data node so this setup helps keep the costs down while still providing the recommended resiliency for the masters. Shield gives you the ability to implement full RBAC for you logs, Marvel helps you keep and eye on your cluster, and Watcher allows you to do alerting based on information in your logs. When you combine these features with the comfort of having support it seems like a no-brainer to me.
<h1>A note on log shippers</h1>
Finding shippers has been the single biggest challenge of this setup. My requirements aren't that lofty:
<ul>
	<li>It should be installable via a package manager. On Windows this means it needs to be available via <a title="Chocolatey" href="https://chocolatey.org" target="_blank">Chocolatey</a>. On Linux I prefer it when the vendor provides repositories for Red Hat and Ubuntu based systems.</li>
	<li>It should be fairly light on resources so that it can be integrated into existing systems without a change in resources (particularly RAM).</li>
	<li>It needs to be able to be managed by Puppet</li>
	<li>It needs to output to Redis or at least output JSON</li>
	<li>It needs to support a variety of inputs including flat files</li>
</ul>
Here are some of the pros and cons I found while researching the available options:
<ul>
	<li><a title="Logstash product page" href="https://www.elastic.co/products/logstash" target="_blank">Logstash</a> itself is disappointing here... it requires Java which isn't exactly light on resources. On the receiver-side I do prefer this but may want or need to avoid it on the shipping side.</li>
	<li><a title="Logstash Forwarder at GitHub" href="https://github.com/elastic/logstash-forwarder" target="_blank">Logstash Forwarder</a> is light but only ships via the Lumberjack protocol. To get this into a broker such as Redis I would have to first route it through a Logstash instance. On the up side it does support encryption so it may be of use for certain hosts.</li>
	<li><a title="Beaver at GitHub" href="https://github.com/josegonzalez/python-beaver" target="_blank">Beaver</a>, a python application, doesn't support Windows Event Log and doesn't really offer anything to tempt me away from other options.</li>
	<li><a title="Woodchuck on GitHub" href="https://github.com/danryan/woodchuck" target="_blank">Woodchuck</a> is written in Ruby which is also a dependency of Puppet so is already installed on all nodes. On the downside, it doesn't support Windows Event Log nor does it support tagging.</li>
	<li><a title="Fluentd website" href="http://www.fluentd.org" target="_blank">Fluentd</a> is actually quite nice and looks more and more like what I will end up using as my shipper on non-Windows servers. It can also be used instead of Logstash on the receiving side. I tried an Elasticsearch, Fluentd, and Kibana stack and just didn't like the format of the data nearly as much. Fluentd also offers integration with programming languages including:
<ul>
	<li><a title="Fluentd and PHP" href="http://docs.fluentd.org/articles/php" target="_blank">PHP</a></li>
	<li><a title="Fluentd and Ruby" href="http://docs.fluentd.org/articles/ruby" target="_blank">Ruby</a></li>
	<li><a title="Fluentd and Node.js" href="http://docs.fluentd.org/articles/nodejs" target="_blank">Node.js</a></li>
	<li><a title="Fluentd and Java" href="http://docs.fluentd.org/articles/java" target="_blank">Java</a></li>
</ul>
This allows for logging directly from applications instead of to a flat file that then must be read and parsed.</li>
</ul>
<h1>Conclusion</h1>
All in all I have been absolutely amazed at how easy everything has been to setup. I am quite impressed with everything thus far and am looking forward to finishing my scale out so that I can start shipping logs from many more sources. I plan to start bringing in logs from all servers and their applications, from switches and access points, and everywhere else I can think of.