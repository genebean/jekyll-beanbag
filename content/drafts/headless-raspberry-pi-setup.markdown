---
author: gene
title: Headless Raspberry Pi Setup
---

Why another setup guide for a Raspberry Pi? Because I can't find a single one that has all the pieces and am tired of having to re-find all the needed pieces of info every time I set one up.

1. download raspbian stretch lite
2. use etcher to install to sd card
3. unplug the sd card and then plug it back in so its mounted
4. open a terminal and enter these commands:
```
$ touch /Volume/boot/ssh
cat > /Volume/boot/wpa_supplicant.conf <EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="WIFI SSID"
    psk="WIFI PASSWORD"
    id_str="location1"
}
network={
    ssid="WIFI SSID"
    psk="WIFI PASSWORD"
    id_str="location2"
}
EOF```
5. eject sd card
6. plug card into pi, plug power into pi
7. wait a minute or so then...
8. `ssh pi@raspberry.local`
9. look at https://rohankapoor.com/2012/04/americanizing-the-raspberry-pi/
10. 