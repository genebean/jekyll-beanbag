---
author: gene
title: Telegraf on a Raspberry Pi 3
---

This is just a quick guide to document how I installed and configured [Telefraf](https://www.influxdata.com/time-series-platform/telegraf/) on a Raspberry Pi 3 running the Debian Stretch version of [Raspbian](https://www.raspberrypi.org/downloads/raspbian/)

__Repository__

```bash
$ echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee -a /etc/apt/sources.list.d/influxdata.list
$ sudo apt-get update
$ sudo apt-get install telegraf
$ sudo systemctl enable telegraf
```