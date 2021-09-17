---
author: gene 
title: Switching to Linux 
---

For the last four years, macOS has been my primary laptop operating system. I recently decided to try, once again, to make the jump to using Linux instead. So far, things are going well and I'm honestly mind-blown at how far the Linux desktop has come in the last few years. Below is the story of how I got to this glorious new place. 

## This isn’t my first rodeo

I’ve used Linux desktop environments in my personal life since 2004, though seldom as my only or primary setup. Professionally, I’ve tried to do it several times and I’ve made it work for a while here and there. Though I have been quite successful at using it on a secondary machine all along, this story is going to focus on my daily drivers (aka my primary machines). 

![My Fluxbox desktop in October 2007](./fluxbox-desktop-2007-10-24.jpeg “My Fluxbox desktop in October 2007”)

One of the few times I made it work was back in 2007 when my main machine was still a desktop. Back then I was blissfully rocking the [Fluxbox](https://en.wikipedia.org/wiki/Fluxbox) window manager, [root-tail](https://linux.die.net/man/1/root-tail), and [conky](https://github.com/brndnmtthws/conky) on [Gentoo](https://www.gentoo.org). I loved that setup but it was a pain to get working just right, especially since I had multiple monitors. 

## Multiple monitors 

One of the biggest hurdles I’ve faced over the years is that I’m totally addicted to having multiple monitors. Windows and macOS (and OS X before it) “just work” in this regard. Linux, on the other hand, has historically been okay with multiple monitors on desktops thanks to their layout being fixed. (https://wiki.archlinux.org/title/Multihead has some good historical information on this topic.) My problems have mostly been the result of having a dockable laptop. X’s lack of automatically being able to adapt to the differences between docked and undocked made things painful. Yes, I know things like TwinView made this better, but it never seemed to work quite right. This might have been exacerbated by automatic graphics switching (switching from discrete graphics adapters to onboard ones to conserve power) that occurred when on battery, but it also didn’t work well when switching was made manual or disabled entirely. Later, these issues were complicated even more because I became accustomed to having two monitors plus the local laptop’s display. TwinView and other tools through at least 2016 simply had no idea what to do once you went beyond two total displays. The only option was manually configuring X, even after it configuring itself became commonplace. 

## Specialized and/or required apps

Another issue I’ve run into is a need,or strong desire, for apps that simply weren’t available on Linux and didn’t run in [Wine](https://www.winehq.org) reliability. For many years, this included Microsoft Office and the thick client for VMware vCenter. Slightly later, the lack of PowerShell, and thereby VMware’s PowerCLI, also became a major issue. 

## Hello 2021: the year of the Linux desktop (for me)

Fast forward to now and so much has changed. I just started using a Lenovo X1 Carbon (Gen9) with Intel Iris graphics. It came preinstalled with Ubuntu so I wasn’t worried about hardware compatibility at all. 

### Ubuntu 20.04 (preinstalled version)

Im not much of a fan of the desktop setup used by stock Ubuntu but I figured I should give the stock setup a spin before trying something else so that I’d have a baseline to compare to. I installed the official driver from DisplayLink, crossed my fingers, and plugged in my dual monitor adapter from StarTech.com…

![Ubuntu 20.04 with DisplayLink adapter](ubuntu-stock-displaylink.jpeg “Ubuntu 20.04 with DisplayLink adapter”)

Holy cow… it worked!

Next, I tried switching to a straight DisplayPort adapter: the Sabrent TH-3DP2.

![Ubuntu 20.04 with DisplayPort adapter](ubuntu-stock-displayport.jpeg “Ubuntu 20.04 with DisplayPort adapter”)

Wow… it worked too! This was a super big deal because it didn’t require any special drivers. No drivers meant every distro should be usable. 


> Notes: monitors just work, app selection, btrfs, targeting Ubuntu lts. 
