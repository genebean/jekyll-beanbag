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

One of the most useful things that has come out of the Podcasting 2.0 initiate is the ability to link a transcript to an episode via the `<podcast:transcript>` tag. Thanks to this, it is becoming much more common for podcasters to produce transcripts by way of hosts like Buzzsprout, services like Otter.ai, or locally Whisper. Additionally, these transcripts support identifying who is speaking much the same way that a set of minutes from a meeting would indicate what Person A said vs what Person B said. Unfortunately, there is a fundamental flaw in the workflow podcasters have been been provided thus far: transcription is generally done based on the same mp3 that is served to listeners in their podcast apps. By the very nature of the mp3 file format, it is a single track of audio. This means that the transcription software has to guess whether Person A or Person B is speaking... and frequently guesses wrong.

Interestingly though, the norm within podcasting is to record each participant as an individual audio track. Also of interest is that all audio editing programs I am aware of podcasters using allow you to import those idividual files, perform any needed edits, and then export one or more of the tracks. This is where the mp3 mentioned earlier comes from: it is usually the byproduct of exporting all the tracks to a single file. 

## A better way

So... what if instead of providing that mp3 with all the tracks combined to the service or software doing the transcription, we provided one file per speaker? Having one file per person speaking would mean there would no longer be a need to guess who was talking at any given moment. Ideally, the service of software doing the transcription would generate a transcript for each file. Once all files have been transcribed, the resulting set of transcripts would then be merged together to create one final transcript that perfectly identifies each speaker at every single moment within the podcast. Hosting proviers and online transcription services could continue to use the guessing-based method if only one file is uploaded and could switch to this new method if additional files are provied. The only real challenge I see with this idea is that I have not yet seen a tool to merge multiple transcripts together... but I also have no doubt that one could be made fairly easily given all the other related tools that do exist. 

Here's hoping this happens sooner rather than later.
