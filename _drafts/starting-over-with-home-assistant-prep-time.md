---
author: gene
title: Starting Over with Home Assistant - Prep Time
---

The other day I [posted this question](https://www.reddit.com/r/homeassistant/comments/t5rsg4/starting_over_maybe/) to Redit:

> I’m seriously considering redoing my Home Assistant setup from scratch now that I know what we actually use and what’s just cruft… anyone else done this?

As expected, there were a variety of opinions. Surprisingly though, there was an overwhelming consensus that redos after having used [Home Assistant](https://www.home-assistant.io) for a whe were a good thing.

After reading all the comments and thinking about things more, I’ve decided I want to download all my backups, copy out several bits of yaml, export some other settings, and then take the plunge. In my “[Introducing My Home Assistant Setup](https://beanbag.technicalissues.us/introducing-my-home-assistant-setup/)” post I said I’d be following up with one that breaks down all my automations. This new decision is going to delay that a bit. Instead, I’m going to start by chronicling my journey through rebuilding my setup.

## Prep Time

Before I actually wipe everything and start over I need to do some prep work. This includes:

* analyzing what bits we actually use
* downloading all my backups
* screenshotting everything so I can reference it later (dashboards, integrations list, add-on list, etc)
* exporting the yaml of each dashboard
* exporting the yaml of each automation and script
* exporting all of my config files
* screenshotting and exporting all of my [Node-RED](https://nodered.org) flows
* exporting all the yaml from my ESPHome devices
* exporting any needed bits from my Tasmota and WLED devices
* exporting settings from my addons

### Naming is Hard

I’m also going to take some time and define a new naming convention for everything while I can still see a full list of devices. I’ve found that having well named devices makes so many things simpler, especially dashboarding.

## Next Steps

After doing all the backups, my plan is to wipe everything and reinstall Home Assistant OS. I already boot my Pi from an external drive, but the process for doing so has changed since I set things up. For this reason, I plan to double check everything to ensure I’m following current best practices, which may mean I have to utilize Raspberry Pi OS as an intermediary step for firmware updates. 

Once Home Assistant is reinstalled I’ll start adding devices and automations back slowly and methodically. This methodical process may well result in wanting to reset things an additional couple of times, and that’s okay. I’d much rather have a little extra down time now than be unhappy after everything has been added back in.

### Changing Zigbee Software

One planned change in particular might be the cause of some redos: I’m going to be switching from [ZHA (Zigbee Home Automation)](https://www.home-assistant.io/integrations/zha/) to [Zigbee2MQTT (z2m)](https://www.zigbee2mqtt.io/). Though I’ve used both before, I didn’t discover z2m until after I’d set everything up at home. I like it a lot more and think I’ll put it to use as part of the redo.

### Adding Z-Wave

We’ve also been planning to start using a couple of Z-Wave devices and I think now is the time to finally do so. As part of this, I’m thinking I’ll use the [Z-Wave JS to MQTT add-on](https://github.com/hassio-addons/addon-zwavejs2mqtt). It won’t surprise me any at all if I need to try a few different times to get things just right. 