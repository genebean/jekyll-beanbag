---
author: gene
title: Local Puppet Module Development, Part 1
---

This post is the first in a series that aims to show the methodology that I use to develop Puppet modules on my laptop. The series is broken up into:

- Part 1: How I setup my development environment
- Part 2: How I put the things from this post to use to create or update a module
- Part 3: Reworking an existing module to use the methodologies from Part 2.

## Table of Contents <!-- omit in toc -->

- [My development environment](#my-development-environment)
  - [Notes about my laptop(s)](#notes-about-my-laptops)
  - [Tools used](#tools-used)
    - [iTerm2](#iterm2)
    - [Homebrew](#homebrew)
    - [Shell setup](#shell-setup)
      - [Start using ZSH](#start-using-zsh)
    - [GitHub for hosting my code](#github-for-hosting-my-code)
    - [hub: A GitHub CLI](#hub-a-github-cli)
    - [Puppet Developer Kit (PDK)](#puppet-developer-kit-pdk)
    - [Editor](#editor)
      - [vim](#vim)
        - [Install](#install)
        - [Plugins](#plugins)
        - [Config](#config)
        - [Powerline](#powerline)
        - [End Result](#end-result)
      - [VS Code](#vs-code)
    - [Vagrant & VirtualBox](#vagrant--virtualbox)
      - [Vagrant boxes](#vagrant-boxes)
    - [puppet-moddeps](#puppet-moddeps)
    - [GitHub Changelog Generator](#github-changelog-generator)
      - [Setting up labels for the changelog generator](#setting-up-labels-for-the-changelog-generator)
    - [Puppet Strings](#puppet-strings)
    - [Araxis Merge](#araxis-merge)
- [Ready to dive in?](#ready-to-dive-in)

## My development environment

I use a MacBook Pro as my daily driver both at home and at work, so many of my methods will focus on macOS. Almost all of these tools are also installable on both Windows and Linux though. The two exceptions that I am aware of are Araxis Merge and iTerm: Merge supports Windows but not Linux; iTerm is macOS only. [ConEmu](https://conemu.github.io/) is what I used on Windows a couple of years ago and still looks to be a good option. Linux has a multitude of options but I tend to either use Gnome Terminal and/or [Guake](http://guake-project.org/).

### Notes about my laptop(s)

Both of the laptops I use are currently running macOS Mojave. These, and every laptop I have done development on, have enough horsepower to run at least one virtual machine with two gigabytes of RAM and two CPU cores. I almost never need that many resources in my test VMs but it should give you an idea of what I consider normal when testing things out.

### Tools used

> **NOTE:** You don't _need_ all of the tools I talk about here to get started writing Puppet code. My setup includes several things that I think make me more efficient and/or make things easier. Much of this comes down to personal preference.

Here's a quick overview of the tools I use and how they relate to each other.

- iTerm2
- Homebrew
- a customized shell
- git for versioning my changes
- GitHub for hosting my code
- hub to make interacting with GitHub easier
- the Puppet Developer Kit (PDK) for standardizing modules and enforcing the current best practices
- vim for editing on the command line
- VS Code for graphical editing
  - this is my primary editor for Puppet code
- Vagrant & VirtualBox to test my modules' functionality locally
- puppet-moddeps to automate getting dependencies while in Vagrant
- GitHub Changelog Generator
- Puppet Strings for generating code-related documentation
- Araxis Merge for visual diffs (rarely needed)

There are also a couple of other tools that I used until just recently that are worth mentioning as you may have come across them in your search for information:

- Puppet Blacksmith is a tool for automating the publishing of a module to the Puppet Forge. I have replaced this with calls to the new Puppet Forge API that will be talked about at this year's Contributor Summit.
- modulesync from Vox Pupuli is an awesome tool. I have had to stop using it, due to the PDK using the same config file (`.sync.yml`). Puppet has made the pdksync gem but it is currently lacking many features of modulesync. I am talking with people inside Puppet about how to resolve this pain point.

#### iTerm2

The very first thing I do on any new Mac is install iTerm2 from [https://iterm2.com](https://iterm2.com). This is because I find the stock Terminal app lacking some features I have become accustomed to. The stock app has gotten much better over the last few releases of macOS but it still lacks the ability to do split views or to have any transparency. The latter is not enough of a reason to use another app but the split views are incredibly useful. Here are a few examples of how you can use split views in iTerm:

![iTerm Vertical Split screenshot](../assets/images/posts/local-puppet-module-development-part-1/iterm-vertical-split.png)

![iTerm Horizontal Split screenshot](../assets/images/posts/local-puppet-module-development-part-1/iterm-horizontal-split.png)

![iTerm Multi-Split screenshot](../assets/images/posts/local-puppet-module-development-part-1/iterm-multi-split.png)

You may have noticed in the screenshots above that part of each looks greyed out: this helps you visually identify which view is active. There are many additional customizations available in iTerm beyond what I have talked about here but the split views alone make it so that I highly recommend everyone use it.

The very next thing I do after installing iTerm is grab a set of fonts to use in it:

```bash
$ mkdir ~/repos
$ cd ~/repos
$ git clone https://github.com/powerline/fonts.git powerline-fonts
$ cd powerline-fonts
$ ./install.sh
```

Once that completes, open iTerm's preferences and navigate to `Profiles` and select the profile you wish to use. Click on the heading labeled `Text` and then set the font to [Inconsolata-g for Powerline](https://github.com/powerline/fonts/tree/master/Inconsolata-g) at 12pt. I use this font for two reasons:

1. I like the way it looks.
2. It plays nice with [Powerline](https://powerline.readthedocs.io/en/latest/) (more on this in the section about vim).

To round things out, I do the following additional changes:

- go to the `Color` heading, click on "Color Presets...", and select "Pastel (Dark Background)"
- go to the `Window` heading and adjust the transparency slider so that it's roughly between the q and u of Opaque. I find that this looks nice without letting so much show through that it's distracting.
- go to the `Terminal` heading and verify that "Unlimited scrollback" and "Silence bell" are checked.
- go to `Appearance` (next to `Profiles`) and make sure that
  - the tab bar location is set to top
  - "Show tab bar even when there is only one tab" is checked
  - "Show tab numbers" is checked

These settings are all represented in the screenshots of my terminal you will see below and, with the exception of the scrollback setting, are only here in case you want to make your terminal look just like the screenshots. The unlimited scrollback is actually a change done explicitly for usability: some commands, sets of test output, and observed Puppet runs can produce way more scrollback than the default buffer will hold. By setting the scrollback to unlimited, you are afforded the opportunity to go back and look at the beginning of the last command's output or to go back and look at the output of something you ran earlier in the day.

#### Homebrew

The second thing I do is install Homebrew per the instruction on [https://brew.sh](https://brew.sh). This tool is a package manager for macOS, allowing me to stay sane while installing additional tools and keeping them up-to-date.

#### Shell setup

For many years I used Bash as my shell... and then I was introduced to the awesomeness of the Z shell and Oh My ZSH. I was hooked almost immediately. Below is my setup and why I prefer it over Bash.

![zsh tab completion screenshot](https://res.cloudinary.com/genebean/image/upload/v1556932722/zsh-tab-completion_cv7cd4.png)

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

# the custom config looks for .private-env so let's make it
touch ~/.private-env
```

On some systems I also need a couple of more changes:

```bash
# comment out starting the gpg agent if you are not using it
sed -i 's/^gpg-connect-agent/#gpg-connect-agent/' ~/.zshrc

# if on Linux you don't need the brew plugin
sed -i "s/ brew / /" /home/vagrant/.zshrc
```

`.private-env` is excluded from my dotfiles' git repository and is where I store things like authentication tokes or aliases that are unique to a particular machine. For example, the one on my work computer contains a GitHub token that is used by a couple of tools and also contains these two aliases that make working on our Puppet control repository much simpler:

```zsh
alias plm='cd ~/repos/puppetlabs-modules'
alias plmpr='git push -u origin $(git_current_branch); hub pull-request -b production; hub browse'
```

Thanks to these two aliases I am able to:

- jump directly to my copy of our control repo from anywhere
- push all committed changes in our my local copy of the control repo to the feature branch I am working on, create a pull request for the changes, and then open my web browser to the pull request by simply typing `plmpr`. `plmpr` is short for 'Puppet Labs Modules Pull Request'.

Git needs to be installed for the next step and, because I use a [Yubikey](https://www.yubico.com), I need a version way newer than what ships with macOS. Homebrew rides to the rescue here as it so often does.

```bash
brew install git
```

Next I set up Oh My ZSH per the instructions on [https://ohmyz.sh](https://ohmyz.sh) so that things are both pretty and way more useful. It will use the files from above straight away. You'll also need to grab my theme for the .zshrc downloaded earlier to work correctly:

```bash
# Remove the default custom theme folder...
# there is nothing there that's needed.
$ rm -rf ~/.oh-my-zsh/custom/themes

$ git clone https://github.com/genebean/my-oh-zsh-themes.git ~/.oh-my-zsh/custom/themes
```

There are several ways this shell setup is useful for doing module development. The first of these is the easy case-insensitive tab completion when changing directories or opening files within a module. The second centers around shell aliases and functions that simplify repetitive tasks. Oh My ZSH comes with pre-made aliases for many Git related tasks. Additionally, I have added both functions and shortcut aliases to the .zshrc that was downloaded earlier. I will talk more about this in part two of this series as it'll make more sense when shown in-context.

##### Start using ZSH

Now that you have installed all the needed components, it's a good time to close your current terminal and open a new one so that you can enjoy the fruits of your labor. Completely quit your terminal program (iTerm or Terminal) and then restart it. When you do, you should be greeted with a prompt very similar to this:

```zsh
╔ ☕️  gene:~
╚ᐅ
```

#### GitHub for hosting my code

All my Puppet modules live on GitHub. I know this isn't a tool in the same sense as all the other things mentioned here but it's so key to the process that I felt it deserved a mention.

GitHub is the second most common place for people to go looking for your work: the first is the [Puppet Forge](https://forge.puppet.com). It is also pretty common for people to navigate to your GitHub (or wherever you host your source code) so that they can take a peek under the hood of your module. More on this in part two of the series.

#### hub: A GitHub CLI

As alluded to in the section about shell aliases, I use [hub](https://hub.github.com) to simplify interacting with GitHub from my terminal. It's an incredibly powerful tool but the main thing I use it for is creating pull requests. This will be demonstrated in the next post.

#### Puppet Developer Kit (PDK)

Ahhhh, the [Puppet Developer Kit](https://puppet.com/docs/pdk/1.x/pdk_overview.html)... this one tool has simplified my workflow sooo much and reduced the amount of toil involved in keeping up with standards and best practices for all the code and documents within a module.

Installation instruction for various platforms can be found [here](https://puppet.com/docs/pdk/1.x/pdk_install.html). The process for macOS is:

```zsh
brew cask install puppetlabs/puppet/pdk
```

Once installed, we need to reload our shell's environment so that the PDK is in our path. You _could_ close your shell and re-open it OR you can use one of the aliases from my .zshrc: `sz` (which simply stands for "source zshrc"):

```zsh
╔ ☕️  gene:~
╚ᐅ alias sz
sz='source ~/.zshrc'
```

The PDK is your friend and, like any good friend, you are going to get to know it very well by spending lots of time interacting with it.

#### Editor

CLI or GUI? It's your choice but you don't actually have to choose. I have found that there are actually times where each makes sense. That said, I would encourage you to fully embrace VS Code because it will make your development experience much easier and more productive. If you are a vim aficionado please resist the temptation to install a vim mode plugin for VS Code as you'll loose out on some of the editor's best features.

##### vim

When it comes to editing on the command line, vim is by far the tool I have seen used most often. It is also one of the tools used in the official Puppet training classes. I have chosen to setup mine with several plugins that I have found to simplify things or fill gaps in my workflow over the last few years.

###### Install

First thing first, let's get an up-to-date version of vim installed:

```zsh
$ brew install vim
```

###### Plugins

Next, install [Vundle](https://github.com/VundleVim/Vundle.vim) to manage, and simplify the installation of, all the plugins:

```zsh
$ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

And now for the plugins:

- [altercation/vim-colors-solarized](https://github.com/altercation/vim-colors-solarized) privides a color scheme that I find much more plesant than the defaults.
- [ekalinin/Dockerfile.vim](https://github.com/ekalinin/Dockerfile.vim) provides syntax highlighting for Dockerfiles.
- [elzr/vim-json](https://github.com/elzr/vim-json) provides syntax highlighting for JSON files. This helps with a module's metadta.json and with the metadata files used to describe Puppet Tasks.
- [garbas/vim-snipmate](https://github.com/garbas/vim-snipmate) provides code snippets. This screencast is a good example of it in action: https://vimeo.com/3535418.
- [godlygeek/tabular](https://github.com/godlygeek/tabular) provides a method for lining things up. This screencast demostrates its usefulness: http://vimcasts.org/episodes/aligning-text-with-tabular-vim/.
- [honza/vim-snippets](https://github.com/honza/vim-snippets) provides snippets for use with vim-snipmate.
- [MarcWeber/vim-addon-mw-utils](https://github.com/MarcWeber/vim-addon-mw-utils) is a utility used by vim-snipmate.
- [mrk21/yaml-vim](https://github.com/mrk21/yaml-vim) provides proper indentaion and syntax highlighting for yaml files. This comes in handy when working with Hiera data files or the yaml version of Puppet Plans.
- [rodjek/vim-puppet](https://github.com/rodjek/vim-puppet) provides several niceties for working with Puppet files.
- [tomtom/tlib_vim](https://github.com/tomtom/tlib_vim) is a utility used by vim-snipmate.
- [vim-ruby/vim-ruby](https://github.com/vim-ruby/vim-ruby) provides syntax hightlighting for ruby files.
- [vim-syntastic/syntastic](https://github.com/vim-syntastic/syntastic) provides syntax checking.

Don't worry, you don't have to install these manually... that's what Vundle is for. The list above is just so you can easily checkout out what each plugin does. Granted, some of these are not specific to Puppet development, but I decided to leave them all in for completeness as you may well find them useful.

###### Config

My .vimrc file is commented so I am going to let it speak for itself. I also have a second file that gets imported via a `source` line at the bottom. This is done so that I can use the same .vimrc on both macOS and Linux by symlinking .vimrc_os_specific to the file for that OS.

`.vimrc`:

```vim
filetype off " required by Vundle. filetype is reenabled after Vundle starts

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required for Vundle to work right
Plugin 'VundleVim/Vundle.vim'

Plugin 'altercation/vim-colors-solarized' " provides solorized color scheme
Plugin 'ekalinin/Dockerfile.vim'          " provides syntax highlighting for Dockerfiles
Plugin 'elzr/vim-json'                    " provides syntax highlighting for JSON files
Plugin 'garbas/vim-snipmate'              " provides code snippets
Plugin 'godlygeek/tabular'                " provides a method for lining things up
Plugin 'honza/vim-snippets'               " provides snippets for use with vim-snipmate
Plugin 'MarcWeber/vim-addon-mw-utils'     " a utility used by vim-snipmate
Plugin 'mrk21/yaml-vim'                   " provides indentation and syntax highlighting for yaml
Plugin 'rodjek/vim-puppet'                " provides several niceties for working with Puppet
Plugin 'tomtom/tlib_vim'                  " a utility used by vim-snipmate
Plugin 'vim-ruby/vim-ruby'                " provides syntax highlighting for ruby files
Plugin 'vim-syntastic/syntastic'          " provides syntax checking

" All of your Plugins must be added before the following line
call vundle#end()
filetype plugin indent on    " required for plugins to be able to adjust indent

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
syntax on                      " enable syntax highlighting

set encoding=utf-8
set termencoding=utf-8

set autoindent                                " automatically indent new lines
set background=dark                           " tell vim your terminal has a dark background
set backspace=2                               " make backspace work like most other programs
set expandtab                                 " converts tabs to spaces
set fillchars+=stl:\ ,stlnc:\                 " fix added per powerline troubleshooting docs
set laststatus=2                              " Always display the status line in all windows
set noshowmode                                " Hide the default mode text (e.g. -- INSERT -- below the status line)
set smarttab                                  " helps with expanding tabs to spaces (I think)
set statusline+=%#warningmsg#                 " recommended setting from syntastic plugin
set statusline+=%{SyntasticStatuslineFlag()}  " recommended setting from syntastic plugin
set statusline+=%*                            " recommended setting from syntastic plugin
set t_Co=256                                  " tell vim we have 256 colors to work with

let g:solarized_termtrans = 1                 " This gets rid of the grey background
colorscheme solarized                         " use the solorized set of colors

" This has to come after colorscheme to not be masked
highlight ColorColumn ctermbg=232             " set the color to be used for guidelines
let &colorcolumn=join(range(81,999),",")      " change the background color of everything beyond 80 characters

" settings for the syntastic plugin
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list            = 1
let g:syntastic_check_on_open            = 1
let g:syntastic_check_on_wq              = 0
let g:syntastic_enable_signs             = 1
let g:syntastic_ruby_checkers            = ['rubocop']
let g:syntastic_quiet_messages           = {'level': 'warnings'}

" don't wrap text in markdown files
let g:vim_markdown_folding_disabled      = 1

" import settings that are OS specific
source ~/.vimrc_os_specific
```

The one setting above that I really feel needs some additional explanation is the guideline setup. Guidelines allow you to have a visual reference for a particular column within vim. Many of the coding standards I have seen recommend not exceeding 80 characters on a line. Because of this, I wanted to be able to easily see when I was approaching that limit. The screenshot below demonstrates what the guideline I settled on looks like.

![Vim guideline demo](../assets/images/posts/local-puppet-module-development-part-1/vim-guideline-demo.png)

`.vimrc_os_specific` on macOS:

```vim
" enable powerline
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup
```

`.vimrc_os_specific` on CentOS Linux:

```vim
" enable powerline
set rtp+='/usr/share/vim/addons/plugin/powerline.vim'
```

###### Powerline

As you can see from the .vimrc_os_specific files above, I use [powerline](https://powerline.readthedocs.io/en/latest/). I'll be pointing this tool out in a screenshot in the next section. You need Python 3 as a prerequisite for powerline on macOS. Homebrew has some caveats around how it handles Python because it's a preinstalled application on macOS. I suggest reading about them at https://docs.brew.sh/Homebrew-and-Python to save confusion later. Do the following to install current versions of Python 3 and Python 2:

```zsh
$ brew install python python@2
$ sz
$ which python
/usr/local/bin/python
# if you get something else, please quit iTerm and reopen it.
```

Next, install powerline and a utility it uses called psutil:

```zsh
$ pip install psutil powerline-status
```

> _Note:_ Powerline can do much more than just work within vim. If you would like to use it in additional applications, be sure to have a look at their docs [here](https://powerline.readthedocs.io/en/master/usage.html).

###### End Result

![vim with Powerline editing a Puppet manifest](https://res.cloudinary.com/genebean/image/upload/v1556933185/vim-with-powerline-editing-puppet_dz99ac.png)

Here are some of the key things to notice in this screenshot:

- The code in the manifest has syntax highlighting
- Powerline is the bar that starts with "NORMAL" on a green background. The default theme is what's shown here but many other options are available. See [here](https://powerline.readthedocs.io/en/master/configuration/reference.html#themes) for more details.
  - The bar starts off by showing which mode vim is in (normal or insert)
  - next it shows that I am in a Git repository and on the "develop" branch
  - next is the relative path to the file I opened
  - next is the file format followed by its encoding
  - next is the file type (puppet in this case)
  - next is the line percent
  - last is the row and column of the cursor
- The standard bottom line where information and vim commands are typed is just below Powerline

##### VS Code

![VS Code screenshot of nxlog::config](../assets/images/posts/local-puppet-module-development-part-1/vscode-of-nxlog-config.png)

Aside from being a really nice editor all the way around, there is an official extension for the Puppet language authored by [James Pogran](https://www.linkedin.com/in/jamespogran/) and [Glenn Sarti](https://www.linkedin.com/in/glenn-sarti/). It is actively developed by several Puppet employees as part of their job. The [VS Code Puppet plugin page](https://marketplace.visualstudio.com/items?itemName=jpogran.puppet-vscode) has a wealth of information about what it can do.

VS Code can be installed by following the directions at [https://code.visualstudio.com/docs/setup/mac](https://code.visualstudio.com/docs/setup/mac). Once installed, be sure to follow the part of the guide entitled "Launching from the command line", as it will make life easier for you.

The next step is to install the Puppet extension. To do so, click the square on the left edge that says "Extension (⇧⌘X)" when you mouse over it. Type "Puppet" in the top box, select the one by James Pogran, and then select the "Install" button on the page that opens to the right.

I recommend doing the same for these extensions:

- [Better Align by WWM](https://marketplace.visualstudio.com/items?itemName=wwm.better-align)
- [Markdown All in One by Yu Zhang](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one)
- [Markdown Navigation by AlanWalk](https://marketplace.visualstudio.com/items?itemName=AlanWalk.markdown-navigation)
- [markdownlint by David Anson](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint)
- [Ruby by Peng Lv](https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby)
- [Spell Right by Bartosz Antosik](https://marketplace.visualstudio.com/items?itemName=ban.spellright)

#### Vagrant & VirtualBox

I use [Vagrant](https://www.vagrantup.com) to test out puppet code in a sandboxed environment. Under the hood it utilizes [Virtualbox](https://www.virtualbox.org/) so you will need that also. Go to each of their sites and follow their installation instructions.

##### Vagrant boxes

I publish my own Vagrant boxes that are designed to work with Virtualbox to use when developing or playing around with new software. You can see them all at [https://app.vagrantup.com/genebean](https://app.vagrantup.com/genebean). My centos-7-puppet-latest box is of particular relevance here as it gives you a recent version of CentOS 7 with a fairly up-to-date version of Puppet pre-installed (currently CentOS 7 18.10 + patches and Puppet 6.4.2). I strongly suggest you grab a copy of it for module testing by opening up a separate terminal window after getting Vagrant installed and running this command:

```zsh
vagrant box add genebean/centos-7-puppet-latest
```

Want a newer version of Puppet or want to add the PDK or Bolt? Just add one or more of these lines to your Vagrantfile:

```ruby
config.vm.provision 'shell', inline: 'yum upgrade --assume-yes puppet'
config.vm.provision 'shell', inline: 'yum install --assume-yes pdk'
config.vm.provision 'shell', inline: 'yum install --assume-yes puppet-bolt'
```

> _Note:_ This box is setup to track the rolling release repository, which means that it will pull down a new major version of Puppet if available. I also maintain boxes for the other supported version(s) of Puppet in case that more closely matches your needs. An example of this is my centos-7-puppet5 box.

#### puppet-moddeps

I wrote a gem a while back that I find very helpful when testing a module in a Vagrant box. It's called [puppet-moddeps](https://github.com/genebean/puppet-moddeps) and it's purpose is to install all the modules listed as dependencies in a metadata.json file. You don't need to download it or install it right now... we'll do that inside our Vagrant box later. The idea here is that while developing a module, or enhancing one, you'll need to test things out. To do that, you are going to need to satisfy the module's dependencies and the dependencies of the dependencies. You could do that by running `puppet module install <some module name>` for each dependency but that gets tedious and is hard to script. This module allows you to instead run a single command: `puppet-moddeps <your module>`.

#### GitHub Changelog Generator

[GitHub Changelog Generator](https://github.com/github-changelog-generator/github-changelog-generator) makes keeping your changelog updated very easy. Again, no need to download this right now. This gets added to our modules via the PDK once we enable a couple of settings.

##### Setting up labels for the changelog generator

[Morgan Rhodes](https://github.com/underscorgan) from Puppet has a tool that simplifies several aspects of managing repositories at [underscorgan/community_management](https://github.com/underscorgan/community_management). One of the utilities included is `labels.rb`. This tool will take care of making sure you have all the labels that the changelog generator is expecting and will also set them to the same colors used by Puppet, Inc. on its repos. I suggest going ahead and cloning a copy of the repository locally.

#### Puppet Strings

[Puppet Strings](https://puppet.com/docs/puppet/latest/puppet_strings.html) is another tool that we will install via the PDK on each module. It's used for generating the REFERENCE.md file that is now the standard place to have documentation about your module's classes and types.

#### Araxis Merge

The last tool I want to mention is far and away the best visual diff tool I have seen: [Araxis Merge](https://www.araxis.com/merge). You don't need to grab it right now unless you want to, but I do suggest taking a look at it. They offer it for free to anyone who contributes to an open source project, such as a Puppet module. Learn more about this option at [https://www.araxis.com/buy/open-source](https://www.araxis.com/buy/open-source).

If you do get it, I suggest reading their guide for integrating with Git [here](https://www.araxis.com/merge/documentation-os-x/integrating-with-other-applications.en#Git). You'll want to expand the section entitled "To use Araxis Merge for file comparison and file merging" and add the recommended settings to `~/.gitconfig`.

## Ready to dive in?

This post covered a multitude of tools. Just to reiterate, you don't _need_ all of them to get started writing Puppet code. My setup includes several things that I think make me more efficient and/or make things easier. Wanna see how I put all this to use? Check out the next post in this series.
