---
author: gene
title: 'PowerPress Authorization Flow'
date: 2023-07-12 21:45 -04:00
description: >-
  My proposal for how PowerPress couple implement the <podcast:authorization> tag's authorization flow
image:
  path: '/assets/images/posts/forest-trail-2x1.jpg'
tags:
  - wordpress
  - powerpress
  - podcasting
---

There’s a proposal in the podcast namespace for an authorization tag and I think [PowerPress](https://wordpress.org/plugins/powerpress/), an existing [WordPress](https://wordpress.org/) plugin that facilitates podcast hosting, can implement the same authorization flow as a podcast hosting provider. The proposed authorization flow is described to work something like this when a service wants to confirm a user owns a podcast:

1. Service reads an authorization url from the podcast’s rss feed
2. Service generates a onetime token
3. Service calls authorization url with token & rss feed as parameters
4. Website hosting authorization url verifies it’s the home / host of the feed
5. Website has user log in
6. Website presents user a confirmation page
7. If user confirms, website inserts the token into the `<podcast:txt>` tag
8. Website publishes updated rss feed 
9. If website supports it, it sends a podping to notify watchers of the updated feed
10. Website sends a success response if the feed is updated and a failure response otherwise

User interaction is done at this point. The service still needs to see the updated feed, but that is beyond the bits I want to talk about here. 

This entire flow could be integrated into PowerPress and be completely transparent to the user who installs the plugin in WordPress. Nothing about this flow requires the user to configure anything they haven’t already configured if running PowerPress today because:

* PowerPress already knows what podcast(s) it is hosting
* PowerPress already manages xml tags within the rss feed for the podcast(s) it hosts
* WordPress already knows how to authenticate someone before allowing them to get to any administrative pages
* WordPress plugins have the ability to create new REST API endpoints (see the [WP OAuth Server  plugin](https://wordpress.org/plugins/oauth2-provider/#description) for an example of this)

Given that to operate PowerPress a user must already know how to log into WordPress, this can be a seamless enhancement to PowerPress if it implements the following:

* a new REST API endpoint that would be called by the service mentioned above. It would need to receive and process the parameters defined in the podcast namespace’s specification.
* an administrative page that is presented as the confirmation dialogue. This page would have to process both an affirmative response and a disapproval response from the user
* the insertion of the provided token in the `<podcast:txt>` tag
* the sending of the success or failure response to the requesting service 

Every other aspect of this flow already exists in PowerPress or WordPress itself. If PowerPress adds this functionality, the user gains the ability prove they own a podcast by doing nothing more than having an up-to-date PowerPress plugin installed, logging into WordPress, confirming they want to proceed, and waiting for the updated feed to be seen by the service. 

I don’t think it can get much easier than that.
