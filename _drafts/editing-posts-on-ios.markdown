---
author: gene
title: Editing Posts on iOS
---

As it so happens, I'm not always around a computer when I want to edit a blog post or the documentation for a project I'm working on. I've found several apps designed to make writing on an iPhone or iPad easy and enjoyable. Most of these apps support and/or focus on writing in [markdown](https://www.markdownguide.org). Markdown is commonly used by blogging platforms and is the standard for documentation pages on GitHub. Many of the apps talk about syncing work between devices and some also simplify publishing to WordPress and Medium. Surprisingly though, there's very little said about editing markdown files from a git repository. This post is going to layout the tools and processes I've found that make it possible to write on iOS, save to GitHub, and then publish to one or more blogging platforms.

## Desired Outcomes

The main things I was looking for when I starred down the rabbit hole of investigating writing apps for iOS were live preview of markdown and a way to integrate with my GitHub repositories. I also wanted to be able to easily see a fully rendered version of my document from within the same app. The other thing I was seeking was integration with Medium. Integration with WordPress was also something I was keeping an eye out for as a nice-to-have. My motivation primarily came from wanting to make edits to a [Jekyll](https://jekyllrb.com) blog post I’m working on.

##  The Contenders

* **Bear:**
	* Free or subscription to unlock features
	* $1.49 / month or $14.99 / year
	* has an app for macOS
	* supports markdown but is a walled garden - no ability to access to files stored outside of it and no external synchronization.
* **Byword:**
	* $5.99 one time cost
	* has an app for macOS
	* seems to meet all editor requirements but no git integration
* **Drafts:**
	* Free or subscription to unlock features
	* $1.99 / month or $19.99 / year
	* has an app for macOS
	* doesn’t seem to support external files
* **iA Writer:**
	* $8.99 one time cost
	* seems to meet all editor requirements but no git integration
* **Markdown Pro:**
	* Free or one time $4.99 upgrade to unlock features
	* Has a side-by-side view but not a view where markdown is automatically rendered. 
	* seemed okay but didn’t appear to support Medium or WordPress. Also doesn’t seem to have any git integration.
* **TIG:**
	* Free
	* does almost all the git stuff, has an editor, and is free. The editor is lacking a bit, there isn’t a way to sign a commit, and interacting with repositories over ssh is broken.
* **Working Copy:**
	* Free limited version
	* $15.99 one time cost to enable pushing changes and additional features. A 10 day free trial of the upgrade is available (this is unique and a great feature in my opinion)
	* does all the git stuff and has an editor. The editor doesn’t directly support Medium or WordPress and is generally lacking vs Byword

##  It takes two...

No single app seems to exist that meets my needs. The solution? Use two apps, one editor and one git client, that each integrate with Apple’s Files app. Doing this results in a workflow that looks like this:

1. Clone a repository to your phone or tablet
2. Open or create a document in the repository
3. Save the document
4. Review the observed changes
5. Commit the changes to the repository
6. Push the changes

##  iA Writer

iA Writer does all the required tasks but had a couple of shortcomings:

* It hides the markdown shortcuts on another screen
* It costs more than Byword without any features to justify the additional cost.

## Working Copy + Byword = Success

Working Copy works well. 