---
author: gene 
title: "Fixing powerline in homebrew's vim"
---

For the last few days I have been trying to figure out why, all of a sudden, [powerline](https://powerline.readthedocs.io/en/latest/usage.html) has stopped working in vim. Whenever I start vim I get this error:

```bash
╔ ☕️  gene:~
╚ᐅ vim
Error detected while processing /Users/gene.liverman/.vimrc_os_specific:
line    2:
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'powerline'
line    3:
Traceback (most recent call last):
  File "<string>", line 1, in <module>
NameError: name 'powerline_setup' is not defined
line    4:
Traceback (most recent call last):
  File "<string>", line 1, in <module>
NameError: name 'powerline_setup' is not defined
Press ENTER or type command to continue
```

The part that serious confused me about this was that this worked fine:

```bash
$ python3
Python 3.7.7 (default, Mar 10 2020, 15:43:33)
[Clang 11.0.0 (clang-1100.0.33.17)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> from powerline.vim import setup as powerline_setup
>>>
```

After much digging I found that I could run `:py3 import sys; print(sys.path)` from within vim to see where it was looking for Python. The result was quite surprising:

```plain
['/usr/local/opt/python@3.8/Frameworks/Python.framework/Versions/3.8/lib/python38.zip', '/usr/local/opt/python@3.8/Frameworks/Python.framework/Versions/3.8/lib/pyt
hon3.8', '/usr/local/opt/python@3.8/Frameworks/Python.framework/Versions/3.8/lib/python3.8/lib-dynload', '/usr/local/opt/python@3.8/Frameworks/Python.framework/Ver
sions/3.8/lib/python3.8/site-packages', '_vim_path_']
```

I had no idea why it was using Python 3.8 when the default is still 3.7 per this:

```bash
╔ ☕️  gene:~
╚ᐅ ls -l $(which python3)
lrwxr-xr-x  1 gene.liverman  admin  34 May 12 15:32 /usr/local/bin/python3 -> ../Cellar/python/3.7.7/bin/python3
```

Assuming I didn't actually have a need for 3.8 yet I decided to try uninstalling it and got this:

```bash
╔ ☕️  gene:~
╚ᐅ brew uninstall python@3.8
Error: Refusing to uninstall /usr/local/Cellar/python@3.8/3.8.2
because it is required by asciinema, awscli, glib, ldns, openssh, plantuml, vim and wireshark, which are currently installed.
You can override this and force removal with:
  brew uninstall --ignore-dependencies python@3.8
```

Annnnd now the mystery is solved: the homebrew formula for vim has been upgraded to rely on Python 3.8.

## The Fix

With this new found knowledge I was able to fix the problem by using the instance of `pip3` under the path listed in the output above to install powerline... again.

```bash
╔ ☕️  gene:~
╚ᐅ /usr/local/Cellar/python@3.8/3.8.2/bin/pip3 install powerline-status
```

And with that, the commands below from my `.vimrc_os_specific` file once again work flawlessly:

```vim
" enable powerline
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup
```
