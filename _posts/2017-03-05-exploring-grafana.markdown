---
title: Exploring Grafana
date: '2017-03-05 18:30:46'
---

This weekend I decided to check out [Grafana][grafana]. My first test for it was setting up the [Zabbix backend][zb]. This went much better than I had expected so I started looking at what other data I could pull in. It turns out that Grafana may well be a great tool for centralizing data and metrics from disparate sources. The consensus on the interwebs, as best as I can tell, is that InfluxDB is the backend I should store my metrics in so I'm going try that next. Once InfluxDB is setup my plan is to try out some one-off inputs to it such as:

* [Foreman][tf] and Puppet stats via [foreman_influxdb][fi]
* VMware stats via [vsphere-influxdb-go][vm]
* Veeam metrics to via [veeam_grafana][vg]

I'm also planning to check out several of the inputs listed on the [Telegraf][tg] site including:

* Apache
* Nginx
* MySQL
* PostgreSQL
* MS SQL
* sysstat 
* memcached
* php-fpm
* passenger

One of the many posts online that perked my interest in this was https://denlab.io/setup-a-wicked-grafana-dashboard-to-monitor-practically-anything/

Another big motivator was the idea of displaying info from Apache and IIS logs as talked about at https://www.codeproject.com/Articles/1094405/Powerful-IIS-Apache-Monitoring-dashboard-using. This project parses the logs with [Logstash][ls] and stores them in [Elasticsearch][es]. Grafana then uses Elasticsearch as another backend. The nice thing about this approach is that I could combine the info in the logs with the metrics pulled in from the Apache, php-fpm, and passenger inputs to Telegraf and the info from Zabbix onto a single dashboard for a holistic view of a web server. 


[es]:https://www.elastic.co/products/elasticsearch
[fi]:https://github.com/agx/foreman_influxdb
[grafana]:http://grafana.org
[ls]:https://www.elastic.co/products/logstash
[tf]:https://theforeman.org/
[tg]:https://docs.influxdata.com/telegraf/v1.2/inputs/
[vg]:https://github.com/jorgedlcruz/veeam_grafana
[vm]:https://github.com/Oxalide/vsphere-influxdb-go
[zb]:https://grafana.net/plugins/alexanderzobnin-zabbix-app