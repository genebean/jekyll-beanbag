---
author: gene
title: SSL, Name-based Virtual Hosts, and Let's Encrypt
---

When I started switching everything I could over to https-only I was under the impression that the only option was to tie each host to a single certificate unless I wanted to shell out the big bucks for a wildcard cert. This also meant one host per IP address if I wanted to use the standard port 443. That was two or three years ago. Just a few months ago I learned that SAN certificates were recognized by all the major browsers and started taking advantage of them to reduce the burden of needing two certs to cover things like example.com and www.example.com. In my mind this still required two IP addresses though (one per domain). All this changed tonight when I decided on a whim to see if you could setup Nginx to recognize name-based virtual hosts that were all tied to a single SAN certificate on a single IP. As it turns out, this works just fine (who knew?!?). And, as the icing on the cake, Let's Encrypt supports up to 100 SAN entries per certificate! 

To put thus new found knowledge to the test I reworked my web server. I am now serving two domains and redirecting three more all off of a single Let's Encrypt certificate using just three ssl-enabled server blocks in my nginx.conf. Want to see it for yourself? Go to [beanbag.technicalissues.us][bb] or [uptimed.technicalissues.us][up] and inspect the certificate by clicking on it from the address bar. You'll see that the name on it is beanbag.technicalissues.us. If you scroll down in the details you'll see multiple other domains listed in the SAN section. You can further verify this by visiting [technicalissues.us][ti] or [geneliverman.com][gl]. The proof for these is that you're redirected without seeing a single browser error.

For me, this is a game changer. It opens up so many doors that I thought were closed due to preferring security. 


[bb]:https://beanbag.technicalissues.us 
[up]:https://uptimed.technicalissues.us 
[ti]:https://technicalissues.us 
[gl]:https://geneliverman.com 