---
author: gene
title: Local Puppet Module Development, Part 2
---

This post is the second in a three-part series on how I go about doing Puppet module development. The previous post covered how I setup my development environment. This one will cover how I put the things from the first post to use to create or update a module. It will also walk through creating a module and then updating it. Part three will expand on this post by reworking an existing module to use the methodologies from here.

- [Diving in](#diving-in)
  - [Creating a new module](#creating-a-new-module)
  - [Patching or enhancing someone else's module](#patching-or-enhancing-someone-elses-module)
  - [roles and profiles and the like](#roles-and-profiles-and-the-like)
- [Creating a module](#creating-a-module)
  - [Step 1: Decide on what to write](#step-1-decide-on-what-to-write)
  - [Step 2: Make sure my tools are up to date](#step-2-make-sure-my-tools-are-up-to-date)
  - [Step 3: Create a skeleton via the PDK](#step-3-create-a-skeleton-via-the-pdk)
    - [Running `pdk new module`](#running-pdk-new-module)
    - [Fixing the directory name](#fixing-the-directory-name)
  - [Step 4: Initial git setup and commit](#step-4-initial-git-setup-and-commit)
  - [Step 5: Create a GitHub repository](#step-5-create-a-github-repository)
  - [Step 6: Push the initial code to GitHub](#step-6-push-the-initial-code-to-github)
  - [Step 7: Label setup](#step-7-label-setup)
  - [Step 8: Travis CI setup](#step-8-travis-ci-setup)
  - [Step 9: edit initial files to include my common settings and content](#step-9-edit-initial-files-to-include-my-common-settings-and-content)
  - [Step 10: stub out an initial spec test](#step-10-stub-out-an-initial-spec-test)
  - [Step 11: add some boiler plate to my readme](#step-11-add-some-boiler-plate-to-my-readme)
  - [Step 12: add a LICENSE file](#step-12-add-a-license-file)
  - [Step 13: validate things with the PDK](#step-13-validate-things-with-the-pdk)
  - [Step 14: Push these changes to GitHub to verify Travis is working](#step-14-push-these-changes-to-github-to-verify-travis-is-working)
  - [Step 15: start actual development by looping through](#step-15-start-actual-development-by-looping-through)
  - [Step 16: Test on actual machine](#step-16-test-on-actual-machine)
  - [Step 17: Validate and update docs](#step-17-validate-and-update-docs)
  - [Step 18: Push to GitHub](#step-18-push-to-github)
  - [Step 19: Apply settings in GitHub's web interface](#step-19-apply-settings-in-githubs-web-interface)
  - [Step 20: Release to Puppet Forge](#step-20-release-to-puppet-forge)

## Diving in

In the first post I covered a multitude of tools. Just to reiterate, you don't _need_ all of the tools I talked about there to get started writing Puppet code. My setup includes several things that I think make me more efficient and/or make things easier. Much of this comes down to personal preference. With that said, let's dive into how I put all this stuff to use.

### Creating a new module

My basic workflow for creating a new module looks like this:

1. decide on what to write
2. make sure my tools are up to date
3. create a skeleton via the PDK
4. do an initial git commit
5. use hub to create a repository on GitHub
6. push the initial code to GitHub
7. standardize the issue labels on the repository
8. enable Travis CI on the new repo <-- from here up is in iTerm
9. edit initial files to include my common settings and content <-- from here down is mostly in VS Code
10. stub out an initial `it { is_expected.to compile.with_all_deps }` spec test
11. add some boiler plate to my readme
12. add a LICENSE file
13. validate things with the PDK
14. Push these changes to GitHub to verify Travis is working
15. start actual development by looping through
    1. write/edit puppet code
    2. validate with PDK
    3. write tests
    4. see if expected tests pass locally
    5. Push to GitHub and pay attention to Travis CI results
    6. repeat until code complete
16. test on actual machine
17. validate and update docs
18. push to GitHub
19. apply settings in GitHub's web interface
20. release to Puppet Forge

First and foremost is deciding what to write. Part of that for me is looking at what already exists on the Puppet Forge and then making a determination about creating something new vs extending something existing. This section is going to assume the former was my decision.

After spending the needed time in my browser and deciding to write something new is when I dive into my terminal. As this is the start of a new project I like to make sure I am not working with outdated tools, thus I do the following:

```zsh
$ brew update
$ brew outdated
# look for things related to the task at hand
# here I am going to assume that vim was in the outdated list
$ brew upgrade vim
$ brew cask outdated
# here I am mainly looking to see if my copy of the PDK is up to date
$ brew cask upgrade pdk # this can take an eternity 😕
# install updates to vim plugins
$ vim +PluginInstall! +qall
```

> **NOTE:** any commands not explained in this section will be demonstrated in the walkthrough section. Don't fret if you are not 100% sure what something mentioned here does.

With that out of the way its time to step through the questions provided by `pdk new module`. This creates a directory that doesn't match how you normally see modules listed on GitHub so the next thing I do is rename the newly created directory from `my_module` to `forge_user_name-my_module`. The generated code is all boiler plate at this stage but I still want to have it as a point in the module's history so I initialize my repository and commit everything. Next up is using hub to create the remote repository, pushing my code, and running a ruby script to standardize my issue labels to match what Puppet, Inc uses and what the GitHub Changelog Generator expects. The last part of this prep work is using Travis CI's gem to enable CI for my new module.

This is usually where I jump over to VS Code. When I first open it up I will generally double check the lower left corner and make sure there are not pending updates for the loaded extensions. After that I go about adding in my personal boilerplate content to the module's `metadata.json`, `.sync.yml`, and `README.md` followed by adding a `LICENSE` file and a basic spec test. After doing this I run `pdk update` to pickup the changes to `.sync.yml` and then I like to go ahead and run through `pdk validate` and `pdk test unit` just to make sure I have not done something unintentional. Once the validation is complete I commit my changes and push them. At this stage there still isn't anything particularly interesting about the module but there is enough there that I can verify Travis CI is going to get triggered correctly... if it doesn't then I will troubleshoot why it didn't run and then re-push to see if it is happy.

At this point we have what I feel is the starting point from which we can do development:

- a properly named and filled in module skeleton
- a local git repo
- a local unit testing setup
- a remote git repo
- CI for the remote repo

Here I start to loop through the iterative process of code, validate, write tests, run tests.

> I have never been able to wrap my head around TDD but, if that's in your wheel house, just rearrange the list above as needed.

Once I get to a point where I have something that _should_ work and is passing unit tests I will generally try it out inside a Vagrant box. Once things work in Vagrant as expected I will go back and verify that the in-code documentation is complete and accurate. I will also populate the `README.md`, make sure that `REFERENCE.md` is up-to-date, and generate the initial `CHANGELOG.md`. Next I do any squashing that's needed on my git history and then do a final push to GitHub. This will kick off another Travis CI run that I will want to ensure is passing before doing a release. While I wait for CI is when I go in and make some extra settings changes to my repository such as requiring PR's and preventing force pushes to master.

Last, but not least, I publish the module on the Puppet Forge.

### Patching or enhancing someone else's module

My workflow for patching another module is pretty simple:

1. fork it
2. clone it
3. add the original repository as an remote called "upstream"
4. create a branch for my change
5. code my fix / improvement
6. test
7. push
8. submit a PR

The details of that are totally up to the individual project owner. If they are using the PDK then I use it too... if not then I don't either. The one exception to this is if my PR is all the work needed to convert a module to using the PDK.

### roles and profiles and the like

Just a quick note to mention that the process is a bit different when working with things embedded in a control repository or when you are dealing with code that stays locked behind a firewall. I am not going to get into that in this post but many of the same concepts can be applied if you find them useful.

## Creating a module

With the overview of the process out of the way let's actually create a module from scratch.

### Step 1: Decide on what to write

I have a tool that I wrote a few years ago called [tree-planter](https://github.com/genebean/tree-planter) that is a webhook receiver designed to deploy code trees. It's distributed as a Docker container and it's README suggests using Puppet to deploy it. The one shortcoming here is that, for the most part, a deployment is done by copy/pasting from the README into a profile. I want to simplify this by moving all that example code into a module so that all a user needs to do is fill in a few configuration variables.

### Step 2: Make sure my tools are up to date

Now that I have decided what to write I stepped through updating all my tools just like what was documented above with one exception: I upgrade everything Homebrew said was out of date. I did this mainly because I had not done it recently and I had the time.

```zsh
$ brew update
$ brew outdated
$ brew upgrade
$ brew cask outdated
$ brew cask upgrade
$ vim +PluginInstall! +qall
```

### Step 3: Create a skeleton via the PDK

Now that my tools are up-to-date I am ready to start creating my module. 

#### Running `pdk new module`

```zsh
╔ ☕️  gene:~/repos
╚ᐅ pdk new module
pdk (INFO): Creating new module:

We need to create the metadata.json file for this module, so we're going to ask you 5 questions.
If the question is not applicable to this module, accept the default option shown after each question. You can modify any answers at any time by manually updating the metadata.json file.

[Q 1/5] If you have a name for your module, add it here.
This is the name that will be associated with your module, it should be relevant to the modules content.
--> treeplanter

[Q 2/5] If you have a Puppet Forge username, add it here.
We can use this to upload your module to the Forge when it's complete.
--> genebean

[Q 3/5] Who wrote this module?
This is used to credit the module's author.
--> genebean

[Q 4/5] What license does this module code fall under?
This should be an identifier from https://spdx.org/licenses/. Common values are "Apache-2.0", "MIT", or "proprietary".
--> BSD-3-Clause

[Q 5/5] What operating systems does this module support?
Use the up and down keys to move between the choices, space to select and enter to continue.
--> RedHat based Linux, Debian based Linux

Metadata will be generated based on this information, continue? Yes
pdk (INFO): Module 'treeplanter' generated at path '/Users/gene.liverman/repos/treeplanter', from template 'file:///opt/puppetlabs/pdk/share/cache/pdk-templates.git'.
pdk (INFO): In your module directory, add classes with the 'pdk new class' command.
```

#### Fixing the directory name

```zsh
╔ ☕️  gene:~/repos
╚ᐅ mv treeplanter genebean-treeplanter
```

### Step 4: Initial git setup and commit

Run `brew install git` if you have not already done so.

```zsh
╔ ☕️  gene:~/repos
╚ᐅ cd genebean-treeplanter

╔ ☕️  gene:~/repos/genebean-treeplanter
╚ᐅ git init
Initialized empty Git repository in /Users/gene.liverman/repos/genebean-treeplanter/.git/

╔ ☕️  gene:~/repos/genebean-treeplanter (master ✘) ✭
╚ᐅ git add .

╔ ☕️  gene:~/repos/genebean-treeplanter (master ✘) ✚
╚ᐅ git commit -am 'Initial commit'
[master (root-commit) 26bb5d9] Initial commit
 20 files changed, 725 insertions(+)
 create mode 100644 .fixtures.yml
 create mode 100644 .gitattributes
 create mode 100644 .gitignore
 create mode 100644 .gitlab-ci.yml
 create mode 100644 .pdkignore
 create mode 100644 .puppet-lint.rc
 create mode 100644 .rspec
 create mode 100644 .rubocop.yml
 create mode 100644 .travis.yml
 create mode 100644 .yardopts
 create mode 100644 CHANGELOG.md
 create mode 100644 Gemfile
 create mode 100644 README.md
 create mode 100644 Rakefile
 create mode 100644 appveyor.yml
 create mode 100644 data/common.yaml
 create mode 100644 hiera.yaml
 create mode 100644 metadata.json
 create mode 100644 spec/default_facts.yml
 create mode 100644 spec/spec_helper.rb
```

### Step 5: Create a GitHub repository

Run `brew install hub` if you don't already have [hub](https://hub.github.com) installed.

```zsh
╔ ☕️  gene:~/repos/genebean-treeplanter (master ✔)
╚ᐅ hub create -d 'A Puppet module for deploying the tree-planter application'
Updating origin
https://github.com/genebean/genebean-treeplanter
```

### Step 6: Push the initial code to GitHub

```zsh
╔ ☕️  gene:~/repos/genebean-treeplanter (master ✔)
╚ᐅ git push -u origin master
Enumerating objects: 24, done.
Counting objects: 100% (24/24), done.
Delta compression using up to 8 threads
Compressing objects: 100% (19/19), done.
Writing objects: 100% (24/24), 10.46 KiB | 3.49 MiB/s, done.
Total 24 (delta 1), reused 0 (delta 0)
remote: Resolving deltas: 100% (1/1), done.
To github.com:genebean/genebean-treeplanter.git
 * [new branch]      master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.
```

### Step 7: Label setup

This next part uses [github.com/underscorgan/community_management](https://github.com/underscorgan/community_management) to configure the issue labels on my module so that they match what's used by Puppet, Inc and what's expected by the GitHub Changelog Generator. The README in the community_management repo documents the tool's setup process. The next steps assume you have followed those directions already.

```zsh
╔ ☕️  gene:~/repos/genebean-treeplanter (master ✔)
╚ᐅ cd ../community_management

╔ ☕️  gene:~/repos/community_management (master ✔)
╚ᐅ bundle exec ruby labels.rb -n genebean -r '^genebean-treeplanter' -f -d
Checking for the following labels: ["needs-squash", "needs-rebase", "needs-tests", "needs-docs", "bugfix", "feature", "tests-fail", "backwards-incompatible", "maintenance"]
Delete: genebean/genebean-treeplanter, ["bug", "duplicate", "enhancement", "good first issue", "help wanted", "invalid", "question", "wontfix"]
Create: genebean/genebean-treeplanter, [{:name=>"needs-squash", :color=>"bfe5bf"}, {:name=>"needs-rebase", :color=>"3880ff"}, {:name=>"needs-tests", :color=>"ff8091"}, {:name=>"needs-docs", :color=>"149380"}, {:name=>"bugfix", :color=>"00d87b"}, {:name=>"feature", :color=>"222222"}, {:name=>"tests-fail", :color=>"e11d21"}, {:name=>"backwards-incompatible", :color=>"d63700"}, {:name=>"maintenance", :color=>"ffd86e"}]
Fix: genebean/genebean-treeplanter, []

╔ ☕️  gene:~/repos/community_management (master ✔)
╚ᐅ cd ../genebean-treeplanter
```

### Step 8: Travis CI setup

I use the [travis gem](https://rubygems.org/gems/travis) to simplify enabling Travis CI tests on a repository. You can install it via `gem install --no-document travis`.

```zsh
╔ ☕️  gene:~/repos/genebean-treeplanter (master ✔)
╚ᐅ travis enable
Detected repository as genebean/genebean-treeplanter, is this correct? |yes|
repository not known to Travis CI (or no access?)
triggering sync: . done
genebean/genebean-treeplanter: enabled :)
```

### Step 9: edit initial files to include my common settings and content




This is usually where I jump over to VS Code. When I first open it up I will generally double check the lower left corner and make sure there are not pending updates for the loaded extensions. After that I go about adding in my personal boilerplate content to the module's `metadata.json`, `.sync.yml`, and `README.md` followed by adding a `LICENSE` file and a basic spec test. After doing this I run `pdk update` to pickup the changes to `.sync.yml` and then I like to go ahead and run through `pdk validate` and `pdk test unit` just to make sure I have not done something unintentional. Once the validation is complete I commit my changes and push them. At this stage there still isn't anything particularly interesting about the module but there is enough there that I can verify Travis CI is going to get triggered correctly... if it doesn't then I will troubleshoot why it didn't run and then re-push to see if it is happy.

At this point we have what I feel is the starting point from which we can do development:

- a properly named and filled in module skeleton
- a local git repo
- a local unit testing setup
- a remote git repo
- CI for the remote repo

### Step 10: stub out an initial spec test

### Step 11: add some boiler plate to my readme

### Step 12: add a LICENSE file

### Step 13: validate things with the PDK

### Step 14: Push these changes to GitHub to verify Travis is working

### Step 15: start actual development by looping through

    1. write/edit puppet code
    2. validate with PDK
    3. write tests
    4. see if expected tests pass locally
    5. Push to GitHub and pay attention to Travis CI results
    6. repeat until code complete

### Step 16: Test on actual machine

### Step 17: Validate and update docs

### Step 18: Push to GitHub

### Step 19: Apply settings in GitHub's web interface

### Step 20: Release to Puppet Forge
