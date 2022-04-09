---
author: gene
title: 'Crash Boom Bang: PoE & Lightning Strikes'
date: 2022-04-09 09:00 -04:00
description: >-
  When lightning strikes and a PoE device doesn't initially come back.
image:
  path: '/assets/images/posts/lightening-2x1.jpg'
tags:
  - homeassistant
  - networking
  - zigbee
---

A couple of days ago there was a severe storm that rolled through my area. Lots of thunder that literally rattled the walls of my house, lightning strikes near by, and high winds. At one point the power blinked out too. No big deal... or at least it wasn't after I realized what was going on. The mystery I am referring to is that when the storm finished I realized my [PoE Zigbee Coordinator](https://www.tubeszb.com/product/cc2652_poe_coordinator/21?cp=true&sa=false&sbp=false&q=false&category_id=2) wasn't back up and running.

At first, it seemed that it had somehow gotten zapped (aka hit by a power surge). Upon digging a little more into the device I found that I could power it via a USB cable. Interestingly, that not only made the device boot up, but also made the ethernet connection work again. This seemed odd because I'd think that anything that fried the PoE aspect of it would have fried the entire ethernet board. With that in mind, I started poking around on my UniFi switch and noticed that there was a power setting for the port that said "off" where the others said "PoE+." I removed the usb power cord from the coordinator, crossed my fingers, and toggled the setting back to "PoE+." Amazingly, all was well!

The really odd part to me was that my UniFi access points that are also powered by the same switch were fine. My best guess as to what happened is that the antenna on the coordinator attracted some of the electricity in the air from the nearby lightning strike and the switch protected itself (this is a total guess though). Regardless of how it happened, I know two things now that I didn't before finding this setting:

- all my equipment survived the storm
- if ever I have another device that won't power up that was working via PoE, I should check this setting

Here's hoping I don't have a reason to need to remember this anytime soon!

## Just in case...

Going on the assumption that my theory of what happened is even remotely possible, I am seriously thinking about getting a [Ethernet Surge Protector](https://store.ui.com/collections/operator-accessories/products/ethernet-surge-protector) from UniFi to put in-line between my coordinator and the switch. They are only $12.50 and seem well worth it. The catch is that I am going to have to have a drain wire installed so that there is a place for any absorbed surge to go. I already have plans to have a contractor I know out soon to do some other work so I will ask him about doing this too. If it isn't cost prohibitive I am going to move forward with the extra protection of my equipment.
