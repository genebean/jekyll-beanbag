---
title: Python PIP Issues after Homebrew upgrade
date: '2017-07-24 05:00:17'
---

This is just a quick note for anyone else out there who recently ran `brew update && brew upgrade` and then found that Python no longer worked as expected. Here are the important points:

* The issue is that Homebrew introduced a breaking change and did a crappy job of documenting it.
* The fix is to prefix your path with `/usr/local/opt/python/libexec/bin`
* More details can be found at https://github.com/Homebrew/homebrew-core/issues/15746

For me, the fix was to add this to my `.zshrc` file: 

```
export PATH="/usr/local/opt/python/libexec/bin:$PATH"
```