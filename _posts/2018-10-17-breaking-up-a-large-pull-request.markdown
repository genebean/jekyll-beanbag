---
title: Breaking up a large pull request
date: '2018-10-17 01:32:22'
---

Ever finished up all the changes for a pull request on GitHub and realized it was just too big to review easily or to reason about what's going on? I had just this issue recently. The solution: create multiple patches that each contain a subset of the changes and use them to generate more manageable pull requests.

For this guide let's make a few assumptions:

- the default branch in your git repo is `master`
- the branch containing the big PR is called `my_massive_change`
- the changes encompass many different files, many of which are in subfolders

To expedite things I am also using [hub](https://hub.github.com/) to interact with GitHub.

Example file structure:

```
╔ ☕️  gene:~/Downloads/my_repo (my_massive_change ✔)
╚ᐅ tree
.
├── a
│   ├── a.txt
│   └── another_file_in_a.txt
├── a.pp
├── b
│   ├── another_file_in_b.txt
│   └── b.txt
├── b.pp
├── c
│   ├── another_file_in_c.txt
│   └── c.txt
├── c.pp
├── d
│   ├── another_file_in_d.txt
│   └── d.txt
├── d.pp
├── e
│   ├── another_file_in_e.txt
│   └── e.txt
├── e.pp
├── f
│   ├── another_file_in_f.txt
│   └── f.txt
├── f.pp
├── g
│   ├── another_file_in_g.txt
│   └── g.txt
├── g.pp
├── h
│   ├── another_file_in_h.txt
│   └── h.txt
└── h.pp

8 directories, 24 files
```

Assuming you made changes related to some root level files and some files in similarly named subfolders you could break your changes up like show below.

First, make a place outside your repo for all the patches:

```
╔ ☕️  gene:~/Downloads/my_repo (my_massive_change ✔)
╚ᐅ mkdir ~/Downloads/patches_for_my_repo/
```

Next, generate patches of related content:

```
╔ ☕️  gene:~/Downloads/my_repo (my_massive_change ✔)
╚ᐅ git diff master a.pp a/ > ~/Downloads/patches_for_my_repo/changes_to_a.patch
╔ ☕️  gene:~/Downloads/my_repo (my_massive_change ✔)
╚ᐅ git diff master b.pp b/ c.pp c/ > ~/Downloads/patches_for_my_repo/changes_to_b_c.patch
╔ ☕️  gene:~/Downloads/my_repo (my_massive_change ✔)
╚ᐅ git diff master e/ g/ > ~/Downloads/patches_for_my_repo/changes_to_e_g.patch
```

These commands each compare the listed files and folders to the master branch and generate a file that contains all the differences. For example, here's what one of the patches looks like:

```
╔ ☕️  gene:~/Downloads/my_repo (my_massive_change ✔)
╚ᐅ cat ~/Downloads/patches_for_my_repo/changes_to_b_c.patch
diff --git a/b/another_file_in_b.txt b/b/another_file_in_b.txt
index e69de29..2ef267e 100644
--- a/b/another_file_in_b.txt
+++ b/b/another_file_in_b.txt
@@ -0,0 +1 @@
+some content
diff --git a/c/another_file_in_c.txt b/c/another_file_in_c.txt
index e69de29..2ef267e 100644
--- a/c/another_file_in_c.txt
+++ b/c/another_file_in_c.txt
@@ -0,0 +1 @@
+some content
```

Now that we have our patches we can use `git apply` to put them to use.

```
# switch to your starting point:
╔ ☕️  gene:~/Downloads/my_repo (my_massive_change ✔)
╚ᐅ git checkout master
Switched to branch 'master'

# make a branch for the patch's changes:
╔ ☕️  gene:~/Downloads/my_repo (master ✔)
╚ᐅ git checkout -b changes_to_a
Switched to a new branch 'changes_to_a'

# apply the changes:
╔ ☕️  gene:~/Downloads/my_repo (changes_to_a ✔)
╚ᐅ git apply ~/Downloads/patches_for_my_repo/changes_to_a.patch
╔ ☕️  gene:~/Downloads/my_repo (changes_to_a ✘) ✹
╚ᐅ git commit -am 'applying changes to a*'
[changes_to_a 4425166] applying changes to a*
 1 file changed, 1 insertion(+)

# push changes to GitHub
╔ ☕️  gene:~/Downloads/my_repo (changes_to_a ✔)
╚ᐅ git push -u origin changes_to_a

# create a pull request that is just for these changes:
╔ ☕️  gene:~/Downloads/my_repo (changes_to_a ✔)
╚ᐅ hub pull-request -m 'changes to a*'
```

Repeat this process for each patch and voilà, you now have a set of PR's that contain the same changes as before but in more manageable chunks.

Want to make sure you got everything or just see what other patches you need to apply once your PR's have been merged? Do this:

```
# get the latest version of master
# that includes the merged changes
$ git checkout master
$ git pull

# Rebase your big change set so that you
# can see how it compares:
$ git checkout my_massive_change
$ git rebase -i master

# Push the updated branch to GitHub so
# you can easily see what's left in the big PR
$ git push -f
```

Once you've generated and applied all the changes you will end up with `my_massive_change` not being any different than `master`.