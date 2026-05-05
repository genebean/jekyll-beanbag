---
author: gene
title: De-forking a Puppet Module
date: 2020-02-26 13:39 -0500
---
A couple of years ago, the team I’m on forked a Puppet module called "mrepo" that is used for creating and managing RPM-based repository mirrors. We recently had an issue arise with using the module, and I happened to notice that the upstream of our fork is now Vox Pupuli and that they had made several improvements that we could benefit from. Those changes, combined with knowing the quality work Vox Pupuli does on all of their modules, made me wonder what it would take to get off our fork and back on to the upstream version.

To suss that out, I looked at the closed pull requests to see what kind of changes we had made since forking from the original repository. Based on what I saw there, all we had really done was:

- add one parameter and an optional bit to an ERB template
- added a regex validation for an architecture we use that the upstream doesn't

That seemed simple enough, and the diffs of each pull request were quite small, so I decided to actually try and submit our changes as a pull request.

I set about working on [my pull request](https://github.com/voxpupuli/puppet-mrepo/pull/107) initially by just submitting it as-is to see what shook out ... turns out that when you are two years behind on commits that doesn't exactly work. At that point, it was time to do what I should have done in the first place: rebase my changes on the current upstream version. Here's what that looks like from a git perspective:

Create a branch in the fork:

```bash
$ git checkout -b move_to_vox_version
```

Squash the six commits that made up our local mods into a single commit:

```bash
$ git rebase -i HEAD~6
```

I still wanted to make sure that credit was given where it was due even though I was squashing all of the commits into one, so I made note of the names and email addresses in the original messages and added a [Co-authored-by](https://medium.com/blackode/creating-co-authored-commits-on-the-command-line-git-305ae2af9f73) line for each to the new commit message.

Pull in the history from upstream:

```bash
$ git remote add upstream https://github.com/voxpupuli/puppet-mrepo.git

$ git fetch --all
```

Rebase local changes onto the current upstream code:

```bash
$ git rebase upstream/master
```

The rebase step included resolving some merge conflicts from where things diverged between the two code bases over the last couple of years. After completing the rebase, I ended up adding some additional changes to our code based on work that had happened upstream. At this stage my single commit's message now looked like this:

```plain
Squashing local mods for upstreaming

This is a combination of the changes below. Attribution for the original
work is done via the co-author lines at the end of this commit.

- Allow passing options to createrepo in mrepo.conf
- Add createrepo_options variable to package class
- Add regex validation for ppc64le architecture
- Modified manifests/repo.pp and added a regex statement for validating
  ppc64le architecture when used in the $arch param.
- Additional changes based on work upstream
  - Added a spec test to cover createrepo_options
  - Fixed duplicate resource declaration in iso.pp
  - Fixed passing params through to ncc and rhn repo types
  - Typed all parameters and replaced empty strings with undef
  - Removed .empty? checks from erb due to Puppet type checking doing this
  - Replaced legacy and top-scope facts

Co-authored-by: Rob Braden <bradejr@puppetlabs.com>
Co-authored-by: Eric Zounes <zounes99@gmail.com>
Co-authored-by: Heston Snodgrass <hsnodgrass3@gmail.com>
Co-authored-by: Erik Hansen <suckatrash@users.noreply.github.com>
```

I felt pretty good about these changes after a good bit of testing via CI on the PR and doing `noop` runs on our server that uses this module, so I commented on the PR that it was ready for review.

Later that same day, Tim Meusel of Vox Pupuli (aka bastelfreak [[1](https://github.com/bastelfreak)] [[2](https://twitter.com/BastelsBlog)]) merged my PR. The changes were even pushed up to the [Forge](https://forge.puppet.com/puppet/mrepo/changelog#v410-2019-11-18) that same day!

After the new version was pushed up to the Forge, I archived the fork of the repo and updated the Puppetfile in our control repository.

Unfortunately, it seems one thing was missed when I added types to everything. 23 days after all of the work above was completed, another user chimed in to say that the new version had an error in it: I had set the parameter `metadata` to only accept strings when it should actually accept both strings and arrays. We chatted back and forth a little and they posted another pull request to correct the issue. A reviewer of the fix rightly indicated that `Variant[Enum['yum','apt','repomd','repoview'],Array[Enum['yum','apt','repomd','repoview']]] $metadata = 'repomd',` was a little too convoluted to have in the parameter section of a manifest and asked the author to create a type instead. The result was the creation of `types/metadata.pp`:

```puppet
type Mrepo::Metadata = Enum['yum','apt','repomd','repoview']
```

After that, the PR author was able to make the parameter definition much simpler:

```diff
  Hash[String, String] $urls                                = {},
- Variant[Enum['yum','apt','repomd','repoview'],Array[Enum['yum','apt','repomd','repoview']]] $metadata = 'repomd',
+ Variant[Mrepo::Metadata,Array[Mrepo::Metadata]] $metadata = 'repomd',
  Mrepo::Update $update                                     = 'nightly',
```

And that's it ... with work done over 3 days (including doing unrelated things) plus helping review a bug report a few weeks later, all of the additions that we used internally are now available to the community at large AND we no longer have to be the sole maintainers of a module. This is absolutely a win-win scenario in my mind. As a bonus, the Vox Pupuli community now has another party with a vested interest in helping maintain one of their many modules, so this is really a win-win-win!

## Learn more

- [Blog post on squashing Git commits](https://stackabuse.com/git-squash-multiple-commits-in-to-one-commit/)
- [Documentation on creating type aliases](https://puppet.com/docs/puppet/latest/lang_type_aliases.html)
- [Vox Pupuli](https://voxpupuli.org)
- [mrepo module](https://forge.puppet.com/puppet/mrepo)

*Gene Liverman is a senior site reliability engineer at Puppet.*
