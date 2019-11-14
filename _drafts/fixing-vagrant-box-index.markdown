---
author: gene
title: Fixing Vagrant's box index
---

I use Vagrant a lot and sometimes things on my laptop get moved around or deleted by means other than `vagrant destroy`. The problem with this is that when I later run `vagrant global-status` it will show me things that don't actually exist anymore. Today I finally got tired of this and figured out how to fix it with minimal pain.

## First things first

Vagrant has added a utility that I just noticed today for cleaning up entries in the global-status... try using it first like so:

```bash
╔ ☕️  gene:~
╚ᐅ vagrant global-status --prune
```

If that doesn't work for whatever reason then the rest of this post is for you.

## Tools

I am going to use two tools to make this relatively easy and both are available via Homebrew:

- [jq](https://stedolan.github.io/jq/) via `brew install jq`
- sponge from [moreutils](https://joeyh.name/code/moreutils/) via `brew install moreutils`

## The Fix

First, run `vagrant global-status` and identify the entry that you want to get rid of. You should get something kinda like this:

```bash
╔ ☕️  gene:~
╚ᐅ vagrant global-status
id       name    provider   state    directory
----------------------------------------------------------------------------------
4fa597c  default virtualbox poweroff /Users/gene/Downloads/drone-testing
fce1b1f  default virtualbox poweroff /Users/gene/Downloads/kubebag
```

Let's assume the second entry is the one I want to get rid of and that none of the methods built into Vagrant for cleaning things up work.

The first step is to get the full-length id:

```bash
╔ ☕️  gene:~
╚ᐅ jq . .vagrant.d/data/machine-index/index |grep fce1b1f
    "fce1b1f8f6fd496a8b5dfe4e4a237380": {
```

With that id in hand we can actually do the cleanup:

```bash
╔ ☕️  gene:~
╚ᐅ cp .vagrant.d/data/machine-index/index Downloads/backup-of-vagrant-index.json

╔ ☕️  gene:~
╚ᐅ jq -c 'walk(if type == "object" and has("fce1b1f8f6fd496a8b5dfe4e4a237380") then del(.fce1b1f8f6fd496a8b5dfe4e4a237380) else . end)' .vagrant.d/data/machine-index/index |sponge .vagrant.d/data/machine-index/index
```

The above commands will make a backup of your current config just in case something goes wrong and then removed the offending entry from the index. You can verify that everything is the way you want it after that by again running `vagrant global-status`.
