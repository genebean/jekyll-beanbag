---
author: gene
title: Temperature sensing for Jupiter Garage
date: 2022-01-30 22:34 -0500
---

The other day I was listening to [Linux Unplugged 441](https://linuxunplugged.com/441) and heard Chris mention how he wished he had a way to track the temperature in the garage where the server is.

I decided that this was something I could help with, so I hit him up on Twitter:

> Hey [@ChrisLAS](https://twitter.com/ChrisLAS) - I was listening to LUP today and heard you might need to monitor temperatures in your garage… DM me if you want a cloudless WiFi monitor based on ESPHome.
>
> &mdash; Technical Issues (@technicalissues) [January 19, 2022](https://twitter.com/technicalissues/status/1483594125832294404)

We chatted a tad via direct messages and then I built this:

![Photo of the device I made]({{ 'assets/images/posts/jupiter-garage-data-photo-cropped.png' | relative_url }})

It's modeled after one I have in my own garage with a couple of small modifications to suite his use case better. The setup is made up of:

* a 1/2 size prototyping board
* a D1 Mini (aka a small ESP8266) microcontroller
* a BME280 temperature, pressure, and humidity sensor
* a 3 port spring terminal block
* a Dallas 1-wire temperature sensor in a waterproof housing with a cable attached

The idea is that [Chris](https://twitter.com/ChrisLAS) will be able to mount this on, or near, the new server cabinet with the microcontroller at the top so that the heat it generates rises above the onboard sensor. The onboard sensor (the purple part) will allow him to monitor the temperature, barometric pressure, and humidity in the garage while the corded sensor will allow for monitoring the temperature inside the server rack.

## Accessing the data directly

The microcontroller is configured to present it's data locally in two ways: via a web page and via a Prometheus endpoint.

### The local web page

This page is presented at [jupiter-garage-data.local](http://jupiter-garage-data.local):

![Screenshot of device web page]({{ 'assets/images/posts/jupiter-garage-data-web-server.png' | relative_url }})

### The Prometheus endpoint

This data is presented at [jupiter-garage-data.local/metrics](http://jupiter-garage-data.local/metrics):

```plain
#TYPE esphome_sensor_value GAUGE
esphome_sensor_value{id="jupiter_garage_data_wifi_signal",name="Jupiter Garage Data WiFi Signal",unit="dBm"} -69
esphome_sensor_value{id="jupiter_garage_data_server_rack_temperature",name="Jupiter Garage Data Server Rack Temperature",unit="°C"} 20.9
esphome_sensor_value{id="jupiter_garage_data_garage_temperature",name="Jupiter Garage Data Garage Temperature",unit="°C"} 20.9
esphome_sensor_value{id="jupiter_garage_data_garage_pressure",name="Jupiter Garage Data Garage Pressure",unit="hPa"} 980.3
esphome_sensor_value{id="jupiter_garage_data_garage_humidity",name="Jupiter Garage Data Garage Humidity",unit="%"} 31.1
#TYPE esphome_sensor_failed GAUGE
esphome_sensor_failed{id="jupiter_garage_data_wifi_signal",name="Jupiter Garage Data WiFi Signal"} 0
esphome_sensor_failed{id="jupiter_garage_data_server_rack_temperature",name="Jupiter Garage Data Server Rack Temperature"} 0
esphome_sensor_failed{id="jupiter_garage_data_garage_temperature",name="Jupiter Garage Data Garage Temperature"} 0
esphome_sensor_failed{id="jupiter_garage_data_garage_pressure",name="Jupiter Garage Data Garage Pressure"} 0
esphome_sensor_failed{id="jupiter_garage_data_garage_humidity",name="Jupiter Garage Data Garage Humidity"} 0
```

## A better way: Home Assistant

Accessing the data locally is all fine and dandy when debugging or doing casual checks, but for everyday usage it is way more helpful to have the data in [Home Assistant](https://www.home-assistant.io/). [ESPHome](https://esphome.io/) supports this out of the box and that's exactly what the code for the microcontroller is built in. Speaking of which, here is the code:

### jupiter-garage-data.yaml

```yaml
substitutions:
  name: jupiter-garage-data
  friendly_name: Jupiter Garage Data
  on_board_sensor_name: Garage
  corded_sensor_name: Server Rack

esphome:
  name: "${name}"

esp8266:
  board: d1_mini

# Enable Home Assistant API
api:
  password: "self-hosted"
  # encryption:
  #   key: !secret enc_key

# Used by fallback Access Point (ap)
captive_portal:

# Enable logging
logger:

ota:
  # only use one of the two lines below
  password: "self-hosted"
  # password: !secret ota_password

prometheus:

web_server:
  port: 80
  # auth:
  #   username: admin
  #   password: !secret ota_password

wifi:
  # the two secret names here are now the ones used by default in ESPHome
  ssid: !secret wifi_ssid
  password: !secret wifi_password

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "${name}-setup"
    password: "self-hosted"

# Set device time to match that of Home Assistant
time:
  - platform: homeassistant
    id: esptime

# Use the onboard LED to indicate system status
status_led:
  pin:
    number: D0
    inverted: true

# Wired sensor
dallas:
  - pin: D4

# The bme280 sensor on the board uses i2c
i2c:
  sda: D2
  scl: D1

sensor:
  - platform: wifi_signal
    name: "${friendly_name} WiFi Signal"
    update_interval: 60s
  - platform: dallas
    address: 0x680000066e92ad28
    name: "${friendly_name} ${corded_sensor_name} Temperature"
  - platform: bme280
    temperature:
      name: "${friendly_name} ${on_board_sensor_name} Temperature"
      oversampling: 16x
    pressure:
      name: "${friendly_name} ${on_board_sensor_name} Pressure"
    humidity:
      name: "${friendly_name} ${on_board_sensor_name} Humidity"
    address: 0x76
    update_interval: 60s
```

Once this device is connected with Home Assistant all the sensors will be availabe for alerts and automations. For example, an automation could be setup to cut on an exhast fan or portable air conditioner if the temperature gets too high. Additionally, if the temperature doesn't come down fast enough an alert could be sent to one or more members of the JB team so that someone can manually intervene before the hardware is damaged.

## Diagrams

Here are a couple of diagrams to help explain things further.

### D1 Mini

In the code above the pins `D0`, `D1`, `D2`, and `D4` are referenced. You can see exactly what those correlate to here:

![diagram of d1 mini microcontroller pinout]({{ 'assets/images/posts/esp8266-wemos-d1-mini-pinout.png' | relative_url }})

*The image above was copied from [https://escapequotes.net/esp8266-wemos-d1-mini-pins-and-diagram/](https://escapequotes.net/esp8266-wemos-d1-mini-pins-and-diagram/)*

### jupiter-garage-data

This diagram shows how I assembled everything:

![diagram of jupiter-garage-data]({{ 'assets/images/posts/jupiter-garage-data.png' | relative_url }})

*This diagram was created with [Fritzing](https://fritzing.org/)*

## Wrap up

Here's hoping Chris likes this device hand finds it useful.
