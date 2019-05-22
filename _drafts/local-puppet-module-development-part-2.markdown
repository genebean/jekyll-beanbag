---
author: gene
title: Local Puppet Module Development, Part 2
---

This post is the second in a three-part series on how I go about doing Puppet module development. The previous post covered how I setup my development environment. This one will cover how I put the things from the first post to use to create or update a module. It will also walk through creating a module and then updating it. Part three will expand on this post by reworking an existing module to use the methodologies from here.

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

The walkthrough section will walk you through creating a module and then updating it.
