---
author: gene
title: 'Self Hosted Photo Archive'
date: 2024-07-10 23:30 -04:00
description: >-
  Consolidating pictures from Google Photos, Dropbox, Facebook, & iOS / iCloud
image:
  path: '/assets/images/posts/foo.png'
tags:
  - photos
  - Immich
---

Over the years, my digital photos have gotten spread out across Google Photos, Dropbox, Facebook, and Apple. I’ve been hearing good things about Immich so I decided to try consolidating all these sources into it. More specifically, I want to no longer depend on there being a copy of my images on Google Photos, Dropbox, or Facebook and I want to back up what’s in iCloud and/or on my iPhone. I intend the result to be a unified view of everything and to also serve as a backup. With regards to the latter, not only will a self hosted instance of Immich be a backup of the cloud services, but I’ll literally take a backup of Immich with restic every day and store it encrypted in Backblaze B2.

Step one was to actually setup Immich. 
- done via compose
- needed new docker on NixOS
- fronted with Nginx

Step two was to test out the setup via its iOS app and a few select uploads. 
- that looked good so I moved on
- started syncing everything from phone
- turned off sleep
- ran in foreground 

Did Google Takeout 
- uploaded with immich-go

Dropbox:
- Setup rclone on laptop
- connected to Dropbox 
- downloaded folders with images
- uploaded with immich-go

Duplicates:
- I had 10,600+ duplicates according to Immich at this stage

Facebook:
- requested export of all posts at highest quality 
- got images and html files
- no exif data
- not sure yet on import process

