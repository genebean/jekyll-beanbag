---
author: gene
title: 'Custom Weather Entity'
date: 2024-04-30 15:00 -04:00
description: >-
  How I created a custom weather entity that pulls current conditions from the weather station in my back yard and forecast data from the Tomorrow.io integration.
image:
  path: '/assets/images/posts/2024-04-30-weather-card-with-my-data.png'
tags:
  - weather
  - forecasts
  - homeassistant
---

![Screenshot of weather card in Home Assistant](/assets/images/posts/2024-04-30-weather-card-with-my-data.png)

In Home Assistant 2024.4, this note was in the "Backward-incompatible changes" section of [the release announcement](https://www.home-assistant.io/blog/2024/04/03/release-20244/)

> The previously deprecated `forecast` attribute of weather entities, has now been removed. Use the [`weather.get_forecasts`](https://www.home-assistant.io/integrations/weather#service-weatherget_forecasts) service to get the forecast data instead.

([@gjohansson-ST](https://github.com/gjohansson-ST) - [#110761](https://github.com/home-assistant/core/pull/110761)) ([documentation](https://www.home-assistant.io/integrations/metoffice))

I had a heck of a time finding docs on this, so I have compiled what I did here.

## Base weather integration

I am using the [Tomorrow.io integration](https://www.home-assistant.io/integrations/tomorrowio/) to get forecasts, but what I have done should work with any weather provider.

## Current Conditions from Weather Station

I have made a custom weather entity that pulls current conditions from the weather station in my back yard and forecast data from the Tomorrow.io integration. The integration is known on my system as `weather.tomorrow_io_leaky_cauldron_daily`.

### Custom Sensors

To make this work, I first needed to make sure my `configuration.yaml` contains this line:

```yaml
template: !include templates.yaml
```

I then edited `templates.yaml` and added this:

```yaml
- trigger:
    - platform: time_pattern
      minutes: /15
  action:
    - service: weather.get_forecasts
      data:
        type: hourly
      target:
        entity_id: weather.tomorrow_io_leaky_cauldron_daily
      response_variable: hourly
    - service: weather.get_forecasts
      data:
        type: daily
      target:
        entity_id: weather.tomorrow_io_leaky_cauldron_daily
      response_variable: daily
  sensor:
    - name: Weather Forecast Hourly
      unique_id: weather_forecast_hourly
      state: "{{ now().isoformat() }}"
      attributes:
        forecast: "{{ hourly['weather.tomorrow_io_leaky_cauldron_daily'].forecast }}"
    - name: Weather Forecast Daily
      unique_id: weather_forecast_daily
      state: "{{ now().isoformat() }}"
      attributes:
        forecast: "{{ daily['weather.tomorrow_io_leaky_cauldron_daily'].forecast }}"
```

This creates two sensors: one with the hourly forecast data and one with the daily forecast data.

### Custom weather entity

Next, I needed to return to `configuration.yaml` and add this:

```yaml
weather:
  - platform: template
    name: "Home + Tomorrow.io"
    unique_id: home_plus_forecast
    condition_template: "{{ states('weather.tomorrow_io_leaky_cauldron_daily') }}"
    temperature_template: "{{ states('sensor.outdoor_weather_station_outdoor_temperature') }}"
    temperature_unit: "°F"
    humidity_template: "{{ states('sensor.outdoor_weather_station_humidity') }}"
    attribution_template: "Home weather station + Tomorrow.io"
    pressure_template: "{{ states('sensor.outdoor_weather_station_absolute_pressure') }}"
    pressure_unit: "inHg"
    wind_speed_template: "{{ states('sensor.outdoor_weather_station_wind_speed') }}"
    wind_speed_unit: "mph"
    wind_bearing_template: "{{ states('sensor.outdoor_weather_station_wind_direction') }}"
    forecast_hourly_template: "{{ state_attr('sensor.weather_forecast_hourly', 'forecast') }}"
    forecast_daily_template: "{{ state_attr('sensor.weather_forecast_daily', 'forecast') }}"
```

The parts of this that have `weather.tomorrow_io_leaky_cauldron_daily` in them are pulled from the Tomorrow.io integration while the parts that start with `sensor.outdoor_weather_station` are pulled from the Ecowitt integration that equates to my weather station.

The result of this is shown below:

![Screenshot of custom weather and daily forecast](/assets/images/posts/2024-04-30-custom-weather-daily.png)

![Screenshot of custom weather and hourly forecast](/assets/images/posts/2024-04-30-custom-weather-hourly.png)
