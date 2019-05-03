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

Covering all this information is going to take some space. The links below should make getting to what you want read next a little easier.

- [My development environment](#my-development-environment)
  - [Notes about my laptop(s)](#notes-about-my-laptops)
  - [Tools used](#tools-used)
  - [Homebrew](#homebrew)
  - [Shell setup](#shell-setup)
    - [Start using ZSH](#start-using-zsh)
  - [GitHub for hosting my code](#github-for-hosting-my-code)
  - [hub: A GitHub CLI](#hub-a-github-cli)
  - [the Puppet Developer Kit (PDK)](#the-puppet-developer-kit-pdk)
  - [vim for editing on the command line](#vim-for-editing-on-the-command-line)
  - [VS Code for graphical editing](#vs-code-for-graphical-editing)
  - [Vagrant & VirtualBox to test my module's functionality locally](#vagrant--virtualbox-to-test-my-modules-functionality-locally)
  - [puppet-moddeps to automate getting dependencies while in Vagrant](#puppet-moddeps-to-automate-getting-dependencies-while-in-vagrant)
  - [GitHub Changelog Generator](#github-changelog-generator)
  - [Puppet Strings for generating code-related documentation](#puppet-strings-for-generating-code-related-documentation)
  - [Araxis Merge for visual diffs (rarely needed)](#araxis-merge-for-visual-diffs-rarely-needed)

## My development environment

I use a MacBook Pro as my daily driver both at home and at work but almost all of this could be applied to Windows or Linux too. I'll note the differences I am aware of as we go.

> **NOTE:** You don't _need_ all of the tools I talk about here to get started writing Puppet code. My setup includes several things that I think make me more efficient and/or make things easier. Much of this comes down to personal preference.

### Notes about my laptop(s)

Both of the laptops I use are currently running macOS Mojave. These, and every laptop I have done development on, have enough horsepower to run at least one virtual machine with two gigabytes of RAM and two CPU cores. I almost never need that many resources in my test VM's but it should give you an idea of what I consider normal when testing things out.

### Tools used

Here's a quick overview of the tools I use and how they relate to each other.

- Homebrew
- a command line interface
- git for versioning my changes
- GitHub for hosting my code
- hub to make interacting with GitHub easier
- the Puppet Developer Kit (PDK) for standardizing modules and enforcing the current best practices
- vim for editing on the command line
- VS Code for graphical editing
  - this is my primary editor for Puppet code
- Vagrant & VirtualBox to test my module's functionality locally
- puppet-moddeps to automate getting dependencies while in Vagrant
- GitHub Changelog Generator
- Puppet Strings for generating code-related documentation
- Araxis Merge for visual diffs (rarely needed)

There are also a couple of other tools that I used until just recently that are worth mentioning as you may have come across them in your search for information:

- Puppet Blacksmith is a tool for automating the publishing of a module to the Puppet Forge. I have replaced this with calls to the new Puppet Forge API that will be talked about at this year's Contributor Summit.
- modulesync from Vox Pupuli is an awesome tool. I have had to stop using it due to the PDK using the same config file as it (`.sync.yml`). Puppet has made the pdksync gem but it is currently lacking many features of modulesync. I am talking with people inside Puppet about how to resolve this pain point.

### Homebrew

The very first thing I do on any new Mac is install Homebrew per the instruction on [https://brew.sh](https://brew.sh). This tool is key to enabling sanity with regards to getting so much of what I use installed and keeping it updated.

### Shell setup

For many years I used Bash as my shell... and then I was introduced to the awesomeness of the Z shell and Oh My ZSH. I was hooked almost immediately. Below is my setup and why I prefer it over Bash.

![](https://res.cloudinary.com/genebean/v1556855450/shell-screenshot-01_xhouki.png)

The screenshot above is of iTerm2 v3.2.9. My font is 12pt [Inconsolata-g for Powerline](https://github.com/powerline/fonts/tree/master/Inconsolata-g) for two reasons:

1. I like the way it looks.
2. it plays nice with [Powerline](https://powerline.readthedocs.io/en/latest/) which I use in both vim and tmux. More on this in the section about vim.

I have set zsh as my default shell via the following process:

```bash
# done in default bash shell

$ brew install zsh zsh-completions
$ which zsh
/usr/local/bin/zsh
# if the path is different you may close
# and reopen your terminal before moving on

$ sudo dscl . -change /Users/$USER UserShell /bin/bash /usr/local/bin/zsh
$ dscl . -read /Users/$USER UserShell
UserShell: /usr/local/bin/zsh
```

After doing what's above, and before starting a new shell that uses zsh, I pull down my `.zshrc` file and create `.private-env` like so:

```bash
curl -sSo ~/.zshrc https://raw.githubusercontent.com/genebean/dots/master/link/nix/zshrc

# comment out starting the gpg agent you are not using it
sed -i 's/^gpg-connect-agent/#gpg-connect-agent/' ~/.zshrc

# If on Linux you don't need the brew plugin
sed -i "s/brew\sbundler/bundler/" /home/vagrant/.zshrc

# the custom config looks for .private-env so let's make it
touch ~/.private-env
```

`.private-env` is excluded from my dotfiles' git repository and is where I store things like authentication tokes or aliases that are unique to a particular machine. For example, the one on my work computer contains a GitHub token that is used by a couple of tools and also contains these two aliases that make working on our Puppet control repository much simpler:

```zsh
alias plm='cd ~/repos/puppetlabs-modules'
alias plmpr='git push -u origin $(git_current_branch); hub pull-request -b production; hub browse'
```

Thanks to these two aliases I am able to:

- jump directly to my copy of our control repo from anywhere
- push all committed changes in our my local copy of the control repo to the feature branch I am working on, create a pull request for the changes, and then open my web browser to the pull request by simply typing `plmpr`. `plmpr` is short 'Puppet Labs Modules Pull Request'.

Git needs to be installed for the next step and, because I use a [Yubikey](https://www.yubico.com), I need a version way newer than what ships with macOS. Homebrew rides to the rescue here as it so often does.

```bash
brew install git
```

Next I set up Oh My ZSH per the instructions on [https://ohmyz.sh](https://ohmyz.sh) so that things are both pretty and way more useful. It will use the files from above straight away.

There are a couple of aspects of this shell setup in the way of usefulness as it relates to doing module development. The first of these is the easy case-insensitive tab completion when changing directories or opening files within a module. The second centers around shell aliases and functions that simplify repetitive tasks. Oh My ZSH comes with pre-made aliases for many Git related tasks. Additionally, I have added both functions and shortcut aliases to the .zshrc that was downloaded earlier. I will talk more about this in the second section of this post as it'll make more sense when shown in-context.

#### Start using ZSH

Now that we have installed all the needed components its a good time to close your current terminal and open a new one so that you can enjoy the fruits of your labor. Completely quit your terminal program (iTerm or Terminal) and then restart it. When you do you should be greeted with a prompt very similar to this:

```zsh
╔ ☕️  gene:~
╚ᐅ
```

### GitHub for hosting my code

All my Puppet modules live on GitHub. I know this isn't a tool in the same sense as all the other things mentioned here but its so key to the process that I felt it deserved a mention.

GitHub is the second most common place for people to go looking for your work: the first is the [Puppet Forge](https://forge.puppet.com). It is also pretty common for people to navigate to your GitHub (or whereever you host your source code) so that they can take a peek under the hood of your module. More on this in the second and third sections of the post.

### hub: A GitHub CLI

As alluded to in the section about shell aliases, I use [hub](https://hub.github.com) to simplify interacting with GitHub from my terminal. Its an incredibly powerful tool but the main thing I use it for is crating pull requests. I'll show example of this later in the post.

### the Puppet Developer Kit (PDK)

Ahhhh, the [Puppet Developer Kit](https://puppet.com/docs/pdk/1.x/pdk_overview.html)... this one tool has simplified my workflow sooo much and reduced the amount of toil involved in keep up with standards and best practices for all the code and documents within a module.

Installation instruction for various platforms can be found at [here](https://puppet.com/docs/pdk/1.x/pdk_install.html). The process for macOS is simply this:

```zsh
brew cask install puppetlabs/puppet/pdk
```

Once installed, we need to reload our shell's environment so that the PDK is in our path. You _could_ close your shell and re-open it OR you can use one of the aliases from my .zshrc: `sz`. `sz` simply stands for "source zshrc" as shown below.

```zsh
╔ ☕️  gene:~
╚ᐅ alias sz
sz='source ~/.zshrc'
```

### vim for editing on the command line

### VS Code for graphical editing

### Vagrant & VirtualBox to test my module's functionality locally

### puppet-moddeps to automate getting dependencies while in Vagrant

### GitHub Changelog Generator

### Puppet Strings for generating code-related documentation

### Araxis Merge for visual diffs (rarely needed)
