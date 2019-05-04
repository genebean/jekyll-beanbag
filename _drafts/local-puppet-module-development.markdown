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
    - [iTerm2](#iterm2)
    - [Homebrew](#homebrew)
    - [Shell setup](#shell-setup)
      - [Start using ZSH](#start-using-zsh)
    - [GitHub for hosting my code](#github-for-hosting-my-code)
    - [hub: A GitHub CLI](#hub-a-github-cli)
    - [the Puppet Developer Kit (PDK)](#the-puppet-developer-kit-pdk)
    - [Editor](#editor)
      - [vim](#vim)
        - [Install](#install)
        - [Plugins](#plugins)
        - [Config](#config)
        - [Powerline](#powerline)
        - [End Result](#end-result)
      - [VS Code](#vs-code)
    - [Vagrant & VirtualBox](#vagrant--virtualbox)
    - [puppet-moddeps](#puppet-moddeps)
    - [GitHub Changelog Generator](#github-changelog-generator)
      - [Setting up labels for the changelog generator](#setting-up-labels-for-the-changelog-generator)
    - [Puppet Strings](#puppet-strings)
    - [Araxis Merge](#araxis-merge)
- [Diving in](#diving-in)
- [Creating a module](#creating-a-module)

## My development environment

I use a MacBook Pro as my daily driver both at home and at work but almost all of this could be applied to Windows or Linux too. I'll note the differences I am aware of as we go.

> **NOTE:** You don't _need_ all of the tools I talk about here to get started writing Puppet code. My setup includes several things that I think make me more efficient and/or make things easier. Much of this comes down to personal preference.

### Notes about my laptop(s)

Both of the laptops I use are currently running macOS Mojave. These, and every laptop I have done development on, have enough horsepower to run at least one virtual machine with two gigabytes of RAM and two CPU cores. I almost never need that many resources in my test VM's but it should give you an idea of what I consider normal when testing things out.

### Tools used

Here's a quick overview of the tools I use and how they relate to each other.

- iTerm2
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

#### iTerm2

The very first thing I do on any new Mac is install iTerm2 from [https://iterm2.com](https://iterm2.com). I strongly suggest you do the same and use it for all your command line needs.

Next I grab a set of fonts to use in iTerm:

```bash
$ mkdir ~/repos
$ cd ~/repos
$ git clone https://github.com/powerline/fonts.git powerline-fonts
$ cd powerline-fonts
$ ./install.sh
```

Once that completes open iTerm's preferences and navigate to `Profiles` and select the profile you wish to use. Click on the heading labeled `Text` and then set the font to [Inconsolata-g for Powerline](https://github.com/powerline/fonts/tree/master/Inconsolata-g) at 12pt. I use this font for two reasons:

1. I like the way it looks.
2. it plays nice with [Powerline](https://powerline.readthedocs.io/en/latest/) which I use in both vim and tmux. More on this in the section about vim.

To round thins out I do the following additional changes:

- go to the `Color` heading, click on "Color Presets...", and select "Pastel (Dark Background)"
- go to the `Window` heading and adjust the transparency slider so that roughly between the q and u of Opaque. I find that this looks nice without letting so much show through that it's distracting.
- go to the `Terminal` heading and verify that "Unlimited scorllback" and "Silence bell" are checked.
- go to `Appearance` (next to `Profiles`) and make sure that
  - the tab bar location is set to top
  - "Show tab bar even when there is only one tab" is checked
  - "Show tab numbers" is checked

These settings are all represented in the screenshots of my terminal you will see below.

#### Homebrew

The second thing I do is install Homebrew per the instruction on [https://brew.sh](https://brew.sh). This tool is key to enabling sanity with regards to getting so much of what I use installed and keeping it updated.

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

Next I set up Oh My ZSH per the instructions on [https://ohmyz.sh](https://ohmyz.sh) so that things are both pretty and way more useful. It will use the files from above straight away. For the .zshrc downloaded earlier will work correctly you'll need to grab my theme:

```bash
# Remove the default custom theme folder...
# there is nothing there that's needed.
$ rm -rf ~/.oh-my-zsh/custom/themes

$ git clone https://github.com/genebean/my-oh-zsh-themes.git ~/.oh-my-zsh/custom/themes
```

There are a couple of aspects of this shell setup in the way of usefulness as it relates to doing module development. The first of these is the easy case-insensitive tab completion when changing directories or opening files within a module. The second centers around shell aliases and functions that simplify repetitive tasks. Oh My ZSH comes with pre-made aliases for many Git related tasks. Additionally, I have added both functions and shortcut aliases to the .zshrc that was downloaded earlier. I will talk more about this in the second section of this post as it'll make more sense when shown in-context.

##### Start using ZSH

Now that we have installed all the needed components its a good time to close your current terminal and open a new one so that you can enjoy the fruits of your labor. Completely quit your terminal program (iTerm or Terminal) and then restart it. When you do you should be greeted with a prompt very similar to this:

```zsh
╔ ☕️  gene:~
╚ᐅ
```

#### GitHub for hosting my code

All my Puppet modules live on GitHub. I know this isn't a tool in the same sense as all the other things mentioned here but its so key to the process that I felt it deserved a mention.

GitHub is the second most common place for people to go looking for your work: the first is the [Puppet Forge](https://forge.puppet.com). It is also pretty common for people to navigate to your GitHub (or whereever you host your source code) so that they can take a peek under the hood of your module. More on this in the second and third sections of the post.

#### hub: A GitHub CLI

As alluded to in the section about shell aliases, I use [hub](https://hub.github.com) to simplify interacting with GitHub from my terminal. Its an incredibly powerful tool but the main thing I use it for is crating pull requests. I'll show example of this later in the post.

#### the Puppet Developer Kit (PDK)

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

The PDK is your friend and, like any good friend, you are going to get to know it very well by spending lots of time interacting with it.

#### Editor

CLI or GUI? It's your choice but you don't actually have to choose. I have found that there are actually time where each makes sense. That said, I would encourage you to fully embrace VS Code because it will make your development experience much easier and more productive. Lastly, if you are a vim aficionado please resist the temptation to install a vim mode plugin for VS Code as you'll loose out on some of the editor's best features.

##### vim

When it comes to editing on the command line vim is by far the choice of Puppet users and Puppet's training material. I have setup my vim with several plugins that I learned about through the Puppet Practitioner training classes along with several others that I have found to simplify things or fill gaps in my workflow over the last few years.

###### Install

First thing first, let's get an up-to-date version of vim installed:

```zsh
$ brew install vim
```

###### Plugins

Next, install [Vundle](https://github.com/VundleVim/Vundle.vim) to manage, and simplify the installation of, all the plugins we're going to use:

```zsh
$ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

And now for the plugins:

- [altercation/vim-colors-solarized](https://github.com/altercation/vim-colors-solarized)
- [ekalinin/Dockerfile.vim](https://github.com/ekalinin/Dockerfile.vim)
- [garbas/vim-snipmate](https://github.com/garbas/vim-snipmate)
- [godlygeek/tabular](https://github.com/godlygeek/tabular)
- [honza/vim-snippets](https://github.com/honza/vim-snippets)
- [MarcWeber/vim-addon-mw-utils](https://github.com/MarcWeber/vim-addon-mw-utils)
- [mrk21/yaml-vim](https://github.com/mrk21/yaml-vim)
- [rodjek/vim-puppet](https://github.com/rodjek/vim-puppet)
- [tomtom/tlib_vim](https://github.com/tomtom/tlib_vim)
- [vim-syntastic/syntastic](https://github.com/vim-syntastic/syntastic)

Don't worry, you don't have to install these manually... that's what Vundle is for. The list above is just so you can easily checkout out what each plugin does. Granted, some of these are not specific to Puppet development but I decided to leave them all in for completeness as you may well find them useful.

###### Config

My .vimrc file is commented so I am going to let it speak for itself. I also have a second file that gets imported via a `source` line at the bottom. This is done so that I can use the same .vimrc on both macOS and Linux by symlinking .vimrc_os_specific to the file for that OS.

`.vimrc`:

```vim
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

Plugin 'altercation/vim-colors-solarized'
Plugin 'ekalinin/Dockerfile.vim'
Plugin 'garbas/vim-snipmate'
Plugin 'godlygeek/tabular'
Plugin 'honza/vim-snippets'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'mrk21/yaml-vim'
Plugin 'rodjek/vim-puppet'
Plugin 'tomtom/tlib_vim'
Plugin 'vim-syntastic/syntastic'

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
syntax on

set encoding=utf-8
set termencoding=utf-8

set autoindent
set background=dark
set backspace=2
set expandtab
set fillchars+=stl:\ ,stlnc:\
set laststatus=2 " Always display the statusline in all windows
set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)
set smarttab
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
set t_Co=256

let g:solarized_termtrans = 1 " This gets rid of the grey background
colorscheme solarized

" This has to come after colorscheme to not be masked
highlight ColorColumn ctermbg=232
let &colorcolumn=join(range(81,999),",")

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list            = 1
let g:syntastic_check_on_open            = 1
let g:syntastic_check_on_wq              = 0
let g:syntastic_enable_signs             = 1
let g:syntastic_ruby_checkers            = ['rubocop']
let g:syntastic_quiet_messages           = {'level': 'warnings'}
let g:vim_markdown_folding_disabled      = 1

source ~/.vimrc_os_specific
```

`.vimrc_os_specific` on macOS:

```vim
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup
```

`.vimrc_os_specific` on CentOS Linux:

```vim
set rtp+='/usr/share/vim/addons/plugin/powerline.vim'
```

###### Powerline

As you can see from the .vimrc_os_specific files above, I use [powerline](https://powerline.readthedocs.io/en/latest/). I'll be pointing this tool out in a screenshot in the next section. To install it do the following:

```zsh
# Details on python at https://docs.brew.sh/Homebrew-and-Python
$ brew install python python@2
$ sz
$ which python
/usr/local/bin/python
# if you get something else please quit iTerm and reopen it.

$ pip install psutil powerline-status
```

###### End Result

![vim with Powerline editing a Puppet manifest](https://res.cloudinary.com/genebean/image/upload/v1556933185/vim-with-powerline-editing-puppet_dz99ac.png)

Here's are some of the key things to notice in this screenshot:

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

As you start to use vim with this new configuration you find that it has many helpful options including automatically indenting code to the right level.

##### VS Code

Aside from be a really nice editor all the way around, there is an official extension for the Puppet language authored by [James Pogran](https://www.linkedin.com/in/jamespogran/). It is actively developed by several Puppet employees as part of their job. The [VS Code Puppet plugin page](https://marketplace.visualstudio.com/items?itemName=jpogran.puppet-vscode) has a wealth of information about what it can do.

VS Code can be installed by following the direction at [https://code.visualstudio.com/docs/setup/mac](https://code.visualstudio.com/docs/setup/mac). Once installed be sure to follow the part of the guide entitled "Launching from the command line" as it will make life easier for you.

The next step is to install the Puppet extension. To do so, click the square on the left edge that says "Extension (⇧⌘X)" when you mouse over it. Type "Puppet" in the top box and select the one by James Pogran and then select "Install" button on the page that opens to the right.

I recommend doing the same for these extensions:

- Better Align by WWM
- Markdown All in One by Yu Zhang
- Markdown Navigation by AlanWalk
- markdownlint by David Anson
- Ruby by Peng Lv
- Spell Right by Bartosz Antosik

Next, navigate to Code > Preferences > Settings, make sure "User Settings" is the selected tab, type pdk in the search box, scroll down a little and change "Puppet: Install Type" to pdk.

#### Vagrant & VirtualBox

I use [Vagrant](https://www.vagrantup.com) to test out puppet code in a sanboxed environment. Under the hood it utilizes [Virtualbox](https://www.virtualbox.org/). Go to each of their sites and follow their installation instructions.

For some time now I have been publishing my own Vagrant boxes to use when developing or playing around with new software. You can see them all at [https://app.vagrantup.com/genebean](https://app.vagrantup.com/genebean). I strongly suggestion you grab a copy of my box used for module testing by opening up a separate terminal window after getting Vagrant installed and running this command:

```zsh
vagrant box add genebean/centos-7-puppet-latest
```

#### puppet-moddeps

I wrote a gem a while back that I find very helpful when testing a module in a Vagrant box. It's called [puppet-moddeps](https://github.com/genebean/puppet-moddeps). You don't need to download it or install it right now... we'll do that inside our Vagrant box later.

#### GitHub Changelog Generator

[GitHub Changelog Generator](https://github.com/github-changelog-generator/github-changelog-generator) makes keeping your changelog updated very easy. Again, no need to download this right now. This gets added to our modules via the PDK once we enable a couple of settings.

##### Setting up labels for the changelog generator

[Morgan Rhodes](https://github.com/underscorgan) from Puppet has a tool that simplifies several aspects of managing repositories at [underscorgan/community_management](https://github.com/underscorgan/community_management). One of the utilities included is `labels.rb`. This tool will take care of making sure you have all the labels that the changelog generator is expecting and will also set them to the same colors used by Puppet, Inc. on its repos. I suggest going ahead and cloning a copy of the repository locally.

#### Puppet Strings

[Puppet Stings](https://puppet.com/docs/puppet/latest/puppet_strings.html) is another tool that we will install via the PDK on each module. It's used for generating the REFERENCE.md file that is now the standard place to have documentation about your modules classes and types.

#### Araxis Merge

The last tool I want to mention is far and away the best visual diff tool I have seen: [Araxis Merge](https://www.araxis.com/merge). You don't need to grab it right now unless you want to but I do suggest taking a look at it. They offer it for free to anyone who contributes to an open source project such as a Puppet module. Learn more about this option at [https://www.araxis.com/buy/open-source](https://www.araxis.com/buy/open-source).

If you do get it I suggest reading their guide for integrating with Git [here](https://www.araxis.com/merge/documentation-os-x/integrating-with-other-applications.en#Git). You'll want to be sure to expand the section entitled "To use Araxis Merge for file comparison and file merging" and add the recommended settings to `~/.gitconfig`.

## Diving in

In the second section I'll dive into the how I put the things from the first section to use to create or update a module.

## Creating a module

The third section will walk you through creating a module and then updating it.
