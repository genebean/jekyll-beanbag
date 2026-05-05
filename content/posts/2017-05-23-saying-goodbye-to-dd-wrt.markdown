---
author: gene
title: Saying Goodbye to dd-wrt
---

Tonight I had to wave a sad goodbye to [dd-wrt](https://www.dd-wrt.com) and revert back to a stock firmware. This travesty is because the [dd-wrt firmware](https://www.dd-wrt.com/site/support/other-downloads) doesn't support the hardware NAT function on the [TP-Link Archer C7 v2](http://www.tp-link.com/us/download/Archer-C7_V2.html) which resulted in losing over two third of my bandwidth. Being that [my ISP](https://waveg.wavebroadband.com/) provides me with a full gigabit upstream and down that equated to a getting only 200-300 megs each way instead of over 900 on a wired connection. On wireless things were even worse: I was getting 100-200 megs vs over 500.

## OpenWRT

It was actually a note on the [OpenWRT page](https://wiki.openwrt.org/toh/tp-link/archer-c5-c7-wdr7500) that led me to discover all this so I feel the need to give them a shout out and a "thanks."

## Reverting to Stock

Getting back to stock was more complicated than expected at first but worked out in the end. Here are a couple of notes in case anyone else it trying to do this too:

1. Download the latest stock firmware from http://www.tp-link.com/us/download/Archer-C7_V2.html#Firmware
2. Download the webrevert RAR file from https://www.dd-wrt.com/phpBB2/viewtopic.php?p=758680 
3. UnRAR the file and "upgrade" via the dd-wrt interface to the extracted .bin file.
4. Upgrade to the newest stock firmware via stock interface.
5. Change the password and update all the settings.