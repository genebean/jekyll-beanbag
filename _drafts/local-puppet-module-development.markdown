---
title: Local Puppet Module Development
---

This post aims to show the methodology that I use to develop Puppet modules on my laptop. Its broken up into three main sections:

In the first section I will cover how I setup my development environment along with:

- the tools I use and how the relate to each other
- shell setup
- tools setup
  - editors (cli and gui)
  - test environment

In the second section I'll dive into the how I put the things from the first section to use to create or update a module.

The third section will walk you through creating a module and then updating it.

## My development environment

I use a MacBook Pro as my daily driver both at home and at work but almost all of this could be applied to Windows or Linux too. I'll note the differences I am aware of as we go.

> **NOTE:** You don't _need_ all of the tools I talk about here to get started writing Puppet code. My setup includes several things that I think make me more efficient and/or make things easier. Much of this comes down to personal preference.

### Notes about my laptop(s)

Both of the laptops I use are currently running macOS Mojave. These, and every laptop I have done development on, have enough horsepower to run at least one virtual machine with two gigabytes of RAM and two CPU cores. I almost never need that many resources in my test VM's but it should give you an idea of what I consider normal when testing things out.

### Tools used

Here's a quick overview of the tools I use and how they relate to each other.

- a command line interface
- git for versioning my changes
- GitHub for hosting my code
- hub to make interacting with GitHub easier
- the Puppet Developer Kit (PDK) for standardizing modules and enforcing the current best practices
- vim for editing on the command line
- VS Code for graphical editing
  - this is my primary editor for Puppet code
- Vagrant & VitrualBox to test my module's functionality locally
- puppet-moddeps to automate getting dependencies while in Vagrant
- GitHub Changelog Generator
- Puppet Strings for generating code-related documentation
- Araxis Merge for visual diffs (rarely needed)

There are also a couple of other tools that I used until just recently that are worth mentioning as you may have come across them in your search for information:

- Puppet Blacksmith is a tool for automating the publishing of a module to the Puppet Forge. I have replaced this with calls to the new Puppet Forge API that will be talked about at this year's Contributor Summit.
- modulesync from Vox Pupuli is an awesome tool. I have had to stop using it due to the PDK using the same config file as it (`.sync.yml`). Puppet has made the pdksync gem but it is currently lacking many features of modulesync. I am talking with people inside Puppet about how to resolve this pain point.

### Shell setup

For many years I used Bash as my shell... and then I was introduced to the awesomeness of the Z shell and Oh My ZSH. Almost was hooked almost immediately. Below is my setup and why I prefer it over Bash.

![](https://res.cloudinary.com/genebean/v1556855450/shell-screenshot-01_xhouki.png)

The screenshot above is of iTerm2 v3.2.9. My font is 12pt [Inconsolata-g for Powerline](https://github.com/powerline/fonts/tree/master/Inconsolata-g) for two reasons:

1. I like the way it looks.
2. it plays nice with [Powerline](https://powerline.readthedocs.io/en/latest/) which I use in both vim and tmux.

I have set zsh as my default shell via the following process:

```
# done in default bash shell

$ brew install zsh zsh-completions
$ which zsh
/usr/local/bin/zsh
# if the path is different close and reopen
# your terminal before moving on

$ sudo dscl . -change /Users/$USER UserShell /bin/bash /usr/local/bin/zsh
$ dscl . -read /Users/$USER UserShell
UserShell: /usr/local/bin/zsh
```

After doing that I proceed to setting up Oh My ZSH so that things are both pretty and way more useful.

