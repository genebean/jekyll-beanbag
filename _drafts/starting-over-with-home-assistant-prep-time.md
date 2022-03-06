---
author: gene
title: Starting Over with Home Assistant - Prep Time
---

The other day I [posted this question](https://www.reddit.com/r/homeassistant/comments/t5rsg4/starting_over_maybe/) to Redit:

> I’m seriously considering redoing my Home Assistant setup from scratch now that I know what we actually use and what’s just cruft… anyone else done this?

As expected, there were a variety of opinions. Surprisingly though, there was an overwhelming consensus that redos after having used [Home Assistant](https://www.home-assistant.io) for a whe were a good thing.

After reading all the comments and thinking about things more, I’ve decided I want to download all my backups, copy out several bits of yaml, export some other settings, and then take the plunge. In my [Introducing My Home Assistant Setup](https://beanbag.technicalissues.us/introducing-my-home-assistant-setup/) post I said I’d be following up with one that breaks down all my automations. This new decision is going to delay that a bit. Instead, I’m going to start by chronicling my journey through rebuilding my setup.

## Prep Time

Before I actually wipe everything and start over I need to do some prep work. This includes:

* analyzing what bits we actually use
* downloading all my backups
* screenshotting everything so I can reference it later (dashboards, integrations list, addons list, etc)
* exporting the yaml of each dashboard
* exporting the yaml of each automation and script
* exporting all of my config files
* screenshotting and exporting all of my [Node-RED](https://nodered.org) flows
* exporting all the yaml from my ESPHome devices
* exporting any needed bits from my Tasmota and WLED devices
* exporting settings from my addons
