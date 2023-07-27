---
author: gene
title: 'Multitrack Podcast Transcripts'
date: 2023-07-12 21:45 -04:00
description: >-
  Podcast transcription is inaccurate by design today... but it doesn't have to be.
image:
  path: '/assets/images/posts/multitrack-podcast-transcripts-2x1.png'
tags:
  - podcasting
  - transcripts
  - transcription
---

![multitrack-podcast-transcripts](https://github.com/genebean/jekyll-beanbag/assets/966789/59274c41-be62-4d09-a562-9c8c243f9a84)

One of the most useful things that has come out of the Podcasting 2.0 initiate is the ability to link a transcript to an episode via the `<podcast:transcript>` tag. Thanks to this, it is becoming much more common for podcasters to produce transcripts by way of hosts like Buzzsprout, services like Otter.ai, or locally Whisper. Additionally, these transcripts support identifying who is speaking much the same way that a set of minutes from a meeting would indicate what Person A said vs what Person B said. Unfortunately, there is a fundamental flaw in the workflow podcasters have been been provided thus far: transcription is generally done based on the same mp3 that is served to listeners in their podcast apps. By the very nature of the mp3 file format, it is a single track of audio. This means that the transcription software has to guess whether Person A or Person B is speaking... and frequently guesses wrong.

Interestingly though, the norm within podcasting is to record each participant as an individual audio track. Also of interest is that all audio editing programs I am aware of podcasters using allow you import those idividual files, perform any needed edits, and then export one or more of the tracks. The mp3 mentioned earlier is usually the byproduct of exporting all the tracks to a single file. But, what if instead of providing that mp3 with all the tracks combined to the service or software doing the transcription, we provided a file per track? Having one file per person speaking would mean there would no longer be a need to guess who was talking at any given moment. Ideally, a transcript would be generated per-file and then the resulting set of transcripts would be merged together based on the time codes in each original file.
