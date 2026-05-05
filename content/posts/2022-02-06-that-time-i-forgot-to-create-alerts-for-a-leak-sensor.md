---
title: That time I forgot to create alerts for a leak sensor
date: 2022-02-20 16:00 -0500
---

I bought and setup a leak sensor... but forgot to have it alert me if it detected water 🤦‍♂️ Here's what happened and my new alerting system.

## How it started

In September of last year I bought an [Aqara Water Leak Sensor](https://www.amazon.com/Aqara-MCCGQ11LM-Window-Sensor-White/dp/B07D39MSZS/) off Amazon. I placed it between my washing machine and hot water heater in the garage and connected it to [Home Assistant](https://www.home-assistant.io) via [ZHA (Zigbee Home Automation) integration ](https://www.home-assistant.io/integrations/zha/) and my [Zigbee Coordinator](https://www.tubeszb.com/product/cc2652_poe_coordinator/21?cp=true&sa=false&sbp=false&q=false&category_id=2). I then added it to a dashboard that shows me information about the garage and the status of my washer and drier. Finally, I tested that the sensor worked as advertised and that the proper state showed in Home Assistant. Everything checked out... yay for being proactive!

## Uh-oh...

Fast forward to the first Friday of February. My wife is on her way to her car in our garage. When she starts down the stairs from our kitchen she hears an odd noise and sees a lot of water on the floor. The water is a concern, but not totally unexpected as our garage has flooded before and it had been raining hard. The odd noise and the fact that there is steam in our garage while it's somewhere around freezing outside is actually much more disturbing. She looks out back and sees that our sump pump is still working, which means it's likely not the issue we've had before. At this point calls me and tells me what she sees and then goes back to investigating.

After getting dressed appropriately, I head down and am equally confused and perplexed. We determine that the steam and noise are coming from behind the washer and drier so I decided to climb atop our drier to get a better look. It turns out both are the result of a leak in a plumbing joint near where the hot water hose connection for our laundry is: high pressure hot water is spewing from the joint. A moment or two later we find the shutoff valve for where water goes into our hot water heater and turn it off. The leak stops and we can start assessing what's happened and the damage.

Having had leaks before, one of the first things that comes to mind is "what is this going to cost us?" It's about this time that I remember two things:

1. I have a leak detector sitting in the flooded area, which means I should be able to determine how long the water has been pouring out into the floor. This will help satisfy some the curiosity related to "is this going to be expensive."
2. I never set up any alerts to tell me when the sensor detected a leak... 🤦‍♂️ Yeah... oops.

I opened up the [Home Assistant app](https://companion.home-assistant.io/) on my phone and pulled up the sensor. It had, indeed, worked as designed and clearly showed that the leak started at about 11:30pm the night before... it was currently about 7:30am.

![screenshot of leak sensor data]({{ 'assets/images/posts/2022-02-04-leak-data.png' | relative_url }})

It's at this point that I'm really wishing I hadn't forgotten to have Home Assistant tell me if the sensor detected water. I set a reminder on my phone to rectify that later in the day and then start removing the water via a push broom (they are surprisingly good at this task, by the way). After moving some things to dry ground and pushing lots of water out the door of our garage, the immediate crisis is over. Now to figure out the root cause and get it fixed.

## Keihan to the rescue!

We are blessed to know an amazing gentleman named Keihan who is a General Contractor and operates his own business focused on residential repairs and upgrades. He and his crew have done almost every bit of work to our house since the day we bought it. So, naturally, my first call after getting the standing water out of our garage was to him. I left a voicemail with all the details about what was going on that morning, and included that I had noticed some sporadic high pressure in our faucets recently.

After checking things out, Keihan determined that the water heater itself was the likely root cause of both the high pressure that periodically showed up in my faucets and in what caused the leak. We made a plan to replace it on Monday and to collect some data over the weekend about the water pressure in my house via a mechanical gauge he attached to the spigot where our water hose would normally be connected. The gauge had an extra needle that would record how high pressure spiked. Keihan asked me to check it periodically and let him know if it spiked much.

### All the pressure

A few hours later, I noticed that the pressure had spiked to about 90 PSI. Street pressure is only about 80 PSI and the regulator for the house is less than that, so this was a little concerning to us both. I dialed the observation needle back down to the current pressure so that we could see if this was a one-off spike or if there was a pattern. I checked again around 8pm and was greeted with this:

![photo of pressure gauge showing nearly 120 PSI]({{ 'assets/images/posts/2022-02-04-high-pressure.jpeg' | relative_url }})

I sent Keihan this photo showing that the pressure had spiked to nearly 120 PSI and he decided we shouldn't wait until Monday as this much pressure could easily expose other weak areas in my house's plumbing. He said he'd be out the following morning, Saturday, to replace the hot water heater. Did I mention that he's awesome?

### Water heater time

Saturday morning came and so did Ro, a long time employee of Keihan's. Ro got right to getting the old water heater drained and prepped for removal. A little bit later, Keihan arrived with the surprisingly hard to acquire new water heater. You see, it was supposedly in stock at the local big box home improvement store... but no one could find it. The next closest store showed to have three of them, so it was off to there. Apparently they were having some inventory difficulties too as it took them an entire hour to find even one unit. Fortunately, they did find it. At any rate, the new hot water heater was at my house and they were ready to get it installed. The old one had well exceeded its life expectancy (which is something I didn't know I needed to watch for) and had developed significant amounts of rust that was already starting to clog the attached pressure tank. One thing was for certain after seeing all the rust and learning the age of the old water heater: it may or may not be the only problem, but it was for sure some of it and truly needed replacing.

### More monitoring

With the new water heater installed and all the air flushed from the lines, all that was left was to keep an eye on the gauge to see if the issue was fully fixed or just partially fixed. The following day, Sunday, I checked the gauge and, sadly, it had spiked above 120 PSI. I let Keihan know and he said Ro would be out the following day to replace the house's pressure regulator.

### Monday

Monday came and so did Ro. He let me know that water was going to be cut off to the house for a little while and then went to work. In what seemed like no time, he was back at the door letting me know he was all finished.

#### Thankful

I have said it before, and I will say it again: I am really thankful that we have access to such a good and reliable contractor. By lunch on Monday everything had been completed and life could return to normal.

## But what about those missing alerts?

The last thing I want is to have a repeat of the 🤦‍♂️ moment where the reason we didn't know about a water leak was that I had simply neglected to make Home Assistant tell us. Thus, it was time to create a new automation.

I though about what I really wanted this alert to do and came up with this as a baseline: it should alert us in a way that we won't miss, regardless of the time of day or night that it goes off, and regardless of us being home or away. There is one catch to this: it also should not terrify my toddler.

### "SOS - Water detected in garage"

Enter my new Home Assistant automation entitled "SOS - Water detected in garage." This automation is triggered any time the leak sensor has been wet for at least one minute. The delay is simply to avoid false alarms and to allow enough time to quickly pick the sensor up if something is spilled near it.

If triggered, the following actions are taken in order:

1. Text messages are sent to my wife and I via Twilio that simply say "Leak detected in the garage."
2. Turns on overhead lights. This includes pretty much every light switch in the house that is not in our toddler's room.
3. Turns off overhead lights
4. Turns on overhead lights
5. Sends a "critical" notification to my wife and I via the Home Assistant app that is installed on each of our phones. This alert contains the text "Water has been detected in the garage" and plays an audio clip with the same message. Of note here is that critical alerts are never silenced, show up on Car Play, and show at the top of your list of alerts.
6. Sets the volume of the Sonos speakers in our bedroom, kitchen, and living room to 30% and combines them into a groups
7. Uses text to speech (TTS) to speak "Attention, attention, attention, a sensor in the garage near the washer is wet"
8. Wait 10 seconds
9. Repeat steps 2-8 up to thirty times

Right now, to make it stop you'd have to go find the automation and turn it off. I plan to improve this by making the notification to our phones "[Actionable](https://companion.home-assistant.io/docs/notifications/actionable-notifications/)." This will allow us to acknowledge the alarm from the notification. Upon acknowledgment the actions listed above will cease.

## Another sensor and reliability enhancement

One thing that was added as part of getting the new hot water heater was a pan beneath it that is intended to catch water in certain scenarios and route it to a safe place. This is great, but also means that the leak sensor sitting next to my washer is no longer sufficient to tell me about everything I'd like to keep an eye on. The solution: add a second leak sensor.

I hopped back on Amazon and ordered another [Aqara Water Leak Sensor](https://www.amazon.com/Aqara-MCCGQ11LM-Window-Sensor-White/dp/B07D39MSZS/) to place in the pan under the water heater. The only problem with this plan is that the pan is metal... and metal is great at blocking or interfering with wireless signals. To combat this, I also picked up a [SONOFF S31 Lite 15A Zigbee Smart Plug](https://www.amazon.com/gp/product/B082PSKRSP/). This plug acts as a Zigbee router, which means that if it were to be plugged in near the sensors then they'd have a strong signal even with the pan causing interference. It just so happens that I had an open place for such a plug in an outlet under my work bench about 10 feet away.

Both the sensor and the plug have come in and have been added to my Home Assistant setup. The new sensor has also been added to the automation that watches for leaks. Here's to hoping that that automation doesn't ever actually need to be triggered.
