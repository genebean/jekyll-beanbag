---
ID: 116
post_title: 'What&#8217;s missing from GitLab?'
author: GeneBean
post_date: 2014-05-02 00:09:53
post_excerpt: ""

permalink: >
  http://beanbag.technicalissues.us/2014/05/whats-missing-from-gitlab/
published: true
---
The other day I was asked what <a href="http://bit.ly/1nRNoIH" target="_blank">GitLab</a> was missing and I realized that, really, it's not much. The single biggest thing to me is the inability to create new projects and interact with existing ones from a remote shell session a la <a href="https://github.com/jingweno/gh/blob/master/README.md">gh / GitHub CLI</a>. Other than that it really comes down to polish and aesthetics. Below is my $0.02 based on interacting with GitLab as a person who runs a server and as an end user.
<!--more-->

<strong>SysAdmin Gripes:</strong>
<ol>
	<li>Really crappy support for running in a subdirectory / relative root such as example.com/gitlab. By crappy I mean what appears to be the <a href="http://bit.ly/1nRNEHH" target="_blank">ignoring of bugs</a> for multiple release cycles; the addition of new <a href="https://github.com/gitlabhq/gitlabhq/commit/8af94ed75505f0253823b9b2d44320fecea5b5fb#diff-9b454209a2f1343b7b950c8c1b867133" target="_blank">Nginx settings</a> that totally disregard the option of a relative root; and having to set the relative root in four different places. That last one goes against all the <a style="font-style: normal" href="http://bit.ly/R64GEu">DRY</a> training I've gotten in the last few years.</li>
	<li>Setting my time zone &amp; keeping it up to date requires me to stash my setting in Git every time there is an upgrade. Why is this editable setting in a source-controlled file?</li>
	<li> No easy way for a non Git guru to take additions and changes to configuration files and merge them into the active config. An example of this was the addition of being able to turn off standard login when using LDAP. Great feature but adding those lines to my code was tedious.</li>
</ol>
<strong>User Gripes:</strong>
<ol>
	<li>As a long time user of both GitHub &amp; Bitbucket I have come to the conclusion that they are right: most people want to see the README on the landing page of a project. In GitLab you have to go elsewhere to see it.</li>
	<li>Public repos are not the most intuitive to find, especially if not logged in. Plus, once you do, their listing is extremely rudimentary. <a href="http://res.cloudinary.com/genebean/image/upload/v1438140569/GitLabPublicView_u16hov.png"><img class="aligncenter size-full wp-image-120" src="http://res.cloudinary.com/genebean/image/upload/v1438140569/GitLabPublicView_u16hov.png" alt="GitLabPublicView" width="735" height="258" /></a></li>
	<li>No warning about crappy support for older versions of IE. As much as I hate it, IE's still the norm. I believe it's the ClearOS project that does this, but I know I've seen custom error pages that users of these old things are redirected to which say politely their browser is old and / or crappy.  That would be much better than letting a user continue on to where they think the application is the problem.</li>
</ol>
Honestly, that's all I can come up with. Overall I really like the project and look forward to where it's going. <del>I do, however, find it sad that https://www.gitlab.com appears to still be vulnerable to <a href="http://bit.ly/1i8jJmD" target="_blank">Heartbleed</a> this long after the issue was brought to light</del>. <em><strong>Update:</strong> I was wrong on this last part... it seems a browser plugin I was using had cached info and told me the site was vulnerable when it was not. The same plugin and other tests show that it is safe now.</em>