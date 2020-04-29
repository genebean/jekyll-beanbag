---
author: gene
title: 'Puppet Camping in place: East meets West'
canonical_url: https://puppet.com/blog/puppet-camping-in-place-east-meets-west/
date: '2020-04-28'
excerpt: A recap of the first virtual Puppet Camp by an experienced camper.
---

![Puppet Camp Tent]({{ 'assets/images/posts/puppet-camp-tent.png' | relative_url }})

I pitched a tent at Puppet Camp a couple of times before joining the company and have to say that last week’s event was superb, and it more than lived up to the standards set in ye olden times. It was great to hang out (virtually) with so many community members! There were some faces, or should I say Slack handles, that I knew, but many more I got to meet and chat with for the first time. The work these gurus are doing in their day jobs is just amazing! The best part is that a lot of what was demoed and talked about is directly applicable to the work that I and the other attendees do. Below are some of my takeaways from the event along with a boatload of reference material from the presenters and people in Slack.

## The day’s focus

The schedule for last week’s camp can loosely be translated to:

1. Keynote from Yvonne Wassenaar, our CEO
2. Making Microsoft GPOs suck less with Puppet
3. Use the best tool for the job, be it Terraform, Puppet, or both
4. A walk through Puppet’s history
5. Ensuring compliance with one or more standards using SIMP
6. Replacing even more GPOs with Puppet
7. A rocking, virtual scavenger hunt

## The keynote

Yvonne kicked things off by talking about what we are doing to help our community navigate the “new normal” such as offering [free Bolt workshops](https://puppet.com/events/), [“ask an expert” office hours](https://puppet.com/community/office-hours/) in Slack, and free access to our Open Source Support Portal through June 2020. She went on to talk about ways we are helping our customers during this time of social distancing and remote-only work. It was pretty cool to see some of the quotes about how we’re making a tangible difference for organizations on the front lines.

She also shared what can be expected from Puppet, including some of the new things coming down the pipe. There was a good bit of excitement in Slack around “Estate Reporting” and our upcoming integrations with ServiceNow. The other topics that caught lots of attention were security, compliance, and patch management. We have a product in alpha today that focuses on CIS compliance, and we’re bringing the great work that [Tony Green](https://www.linkedin.com/in/tgreen4) has done on the [os_patching](https://forge.puppet.com/albatrossflavour/os_patching) module into Puppet Enterprise. She touched on how Puppet Remediate can help IT Operations close the “find it, fix it” loop that gets kicked off by security scans so many of us have come to _love_ over the years. All of this really boiled down to ways we help reduce the time to value for our users.

## Puppet > GPOs

Sometimes it's amazing just how many people are trying to slay the same beast. This is exactly what I saw during the camp with two talks: one from [John Rogers](https://www.linkedin.com/in/totheo), engineer at SwissRe, and [Shane Smith](https://www.linkedin.com/in/shane-smith-2013379), senior site reliability engineer at athenahealth. They are both approaching the problem from different angles but share a common foe: Microsoft Group Policy. In both cases there was a measure of parsing Microsoft’s ADMX files, `.pot` files, and a few other things. Once each file is parsed, Puppet manifests are generated and can then be used to ensure the desired state on a given box.

Both companies have created some pretty awesome tooling around this. Even sweeter is that our community members were clambering not only to get their hands on what’s already been made, but to help these teams that have extremely limited resources improve them! Some brainstorming started up before we even finished the event about how to combine these efforts with the work that [Camptocamp](https://www.camptocamp.com), [Matt Stone](https://www.linkedin.com/in/matthewrstone), and [Michael Lombardi](https://www.linkedin.com/in/michaeltlombardi) are individually doing. The end result of this collaboration seems likely to produce some extremely useful stuff. I can’t wait!

## Using the right tool for the job

[Ranjit](https://www.linkedin.com/in/whatsaranjit) gave a pretty cool overview of automating the deployment of PE and a multi node application stack configured by PE using Terraform. It was a superb example of how combining Puppet, Terraform, and Terraform Cloud can make for an extremely sustainable, and scalable, workflow. After his talk he shared [this link](https://github.com/WhatsARanjit/puppetize2019) to the code used in his presentation so others could try it out in their own environments.

## SIMP has been evolving right along with Puppet since 0.24

[Kendall](https://www.linkedin.com/in/kendall-moore-40ba8713) from [OnyxPoint](https://www.onyxpoint.com) took us down memory lane as a means of helping us understand how and why the [SIMP project](https://www.simp-project.com) packs all of the data from a zillion standards and policies into Puppet modules. This facilitates their SIMP Compliance Engine, which is basically a Hiera backend, and makes sure things are up to snuff from a NIST 800-53 and/or a DISA STIG point of view… and that’s just in the FOSS version! SIMP Enterprise also helps you comply with CIS, HIPPA, SOX, PCI-DSS, GLBA, and CIP. Additionally, it comes with a sweet GUI that gives you the exact line to add to Hiera to resolve something when a scanner such as OpenSCAP says you are out of compliance.

## Let’s hunt!

As if all this wasn’t enough, [Ben Ford](https://www.linkedin.com/in/ben-ford-061b344) sent everyone on a virtual scavenger hunt. Each person had the option of doing their hunt in either a Windows or a Linux VM, and the first few to complete the game got some pretty rocking rewards.

## Slide decks

* [Puppetcamp East, Windows Without GPOs, John Rogers, SwissRe](https://www.slideshare.net/PuppetLabs/puppetcamp-east-windows-without-gpos-john-rogers-swissre)
* [Puppet Camp East, A New Cloud Operating Model, Ranjit Viswakumar, Hashicorp](https://www.slideshare.net/PuppetLabs/puppet-camp-east-a-new-cloud-operating-model-ranjit-viswakumar-hashicorp) and [demo code](https://github.com/WhatsARanjit/puppetize2019)
* [Puppet Camp East, A Decade of Compliance with Puppet, Kendall Moore, OnyxPoint](https://www.slideshare.net/PuppetLabs/2020-puppet-camp226128147kendall-232791485)
* [Puppet Camp East, Converting Group Policy settings to Puppet manifests, Shane Smith, athenahealth](https://www.slideshare.net/PuppetLabs/puppet-camp-east-converting-group-policy-settings-to-puppet-manifests-shane-smith-athenahealth)

## Tools

Several tools were mentioned by presenters and/or community members in Slack. This is a list of the ones I could scrape together from going back over conversations:

### From the keynote

* Transurban’s Puppetize PDX talk on integrating ServiceNow, PE, Slack: [https://www.youtube.com/watch?v=I7ICz2d3DHY](https://www.youtube.com/watch?v=I7ICz2d3DHY)
* Learn more about Relay: [relay.sh](https://relay.sh)
* For more info about Estate Reporting, email [lidar@puppet.com](mailto:lidar@puppet.com)
* Check out Tony Green’s Puppetize PDX talk on patching for Windows and Linux: [https://www.youtube.com/watch?v=Z3JwRygAZz8](https://www.youtube.com/watch?v=Z3JwRygAZz8)
* Get a demo of the new enhancements in Puppet Remediate: [https://puppet.com/products/puppet-remediate/](https://puppet.com/products/puppet-remediate/)
* Check out the Windows Collection page on the Forge: [https://forge.puppet.com/collections/windows](https://forge.puppet.com/collections/windows)
* Open Source Portal: [https://ospsupport.puppet.com/](https://ospsupport.puppet.com/)
* [https://puppet.com/use-cases/continuous-compliance/](https://puppet.com/use-cases/continuous-compliance/)

### Windows-related links

* [https://forge.puppet.com/camptocamp/gpo](https://forge.puppet.com/camptocamp/gpo)
* [https://github.com/johnrogers00/securityoptions](https://github.com/johnrogers00/securityoptions)
* [https://github.com/ShaneSmith-code/WinPuppetTools](https://github.com/ShaneSmith-code/WinPuppetTools)
* [https://forge.puppet.com/fervid/auditpol](https://github.com/ShaneSmith-code/WinPuppetTools)
* DSC + Puppet: Incoming! [https://puppetlabs.github.io/iac/news/roadmap/2020/03/30/dsc-announcement.html](https://puppetlabs.github.io/iac/news/roadmap/2020/03/30/dsc-announcement.html) 
* The “Puppet + DSC: Phase II Begins!” section of [https://puppetlabs.github.io/iac/team/status/2020/04/09/status-update.html#puppet--dsc-phase-ii-begins](https://puppetlabs.github.io/iac/team/status/2020/04/09/status-update.html#puppet--dsc-phase-ii-begins)
  * [Parent epic](https://tickets.puppetlabs.com/browse/IAC-41)
  * [Phase II](https://tickets.puppetlabs.com/browse/IAC-685)
  * [Phase III](https://tickets.puppetlabs.com/browse/IAC-683)
  * [Modularization Ticket(s)](https://tickets.puppetlabs.com/browse/IAC-650)

### European Windows / DevOps events

* [https://www.meetup.com/WinOps/events/270156552/](https://www.meetup.com/WinOps/events/270156552/)
* [https://www.eventbrite.com/e/virtual-puppet-camp-germany-tickets-101250404686](https://www.eventbrite.com/e/virtual-puppet-camp-germany-tickets-101250404686)
* [https://cfgmgmtcamp.eu](https://cfgmgmtcamp.eu) (As [@tuxmea](https://twitter.com/tuxmea) says, it's not a conf, it's a family gathering!)

### General Puppet-related tools

* [https://github.com/WhatsARanjit/puppet-hi5er](https://github.com/WhatsARanjit/puppet-hi5er)
* [https://github.com/acidprime/puppet-catalog-diff/](https://github.com/acidprime/puppet-catalog-diff/)
* [https://github.com/camptocamp/puppet-catalog-diff-viewer](https://github.com/camptocamp/puppet-catalog-diff-viewer)
* [https://github.com/camptocamp/terraform-provider-puppetca](https://github.com/camptocamp/terraform-provider-puppetca)
* [https://github.com/camptocamp/terraform-provider-puppetdb](https://github.com/camptocamp/terraform-provider-puppetdb)
* [https://github.com/WhatsARanjit/puppetize2019](https://github.com/WhatsARanjit/puppetize2019)

## Wrapping up

Again, it was great getting to hang out with everyone and I look forward to doing it again soon! You can find me in the [Community Slack](https://puppetcommunity.slack.com) as `@genebean` most any time. You may also find me at one of the other upcoming camps. Be sure to check out the [Puppet Camp](https://puppet.com/events/puppet-camps/) page for information on where we will pitch our virtual tent next.

_Gene Liverman is a senior site reliability engineer at Puppet._

## Learn more

* Is there an upcoming [Puppet Camp](https://puppet.com/events/puppet-camps/) near you?
* Not part of our [Community Slack](https://puppetcommunity.slack.com) yet? Sign up at [slack.puppet.com](https://slack.puppet.com)
