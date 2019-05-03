---
title: Windows 7 x64 and Underscore-CLI
date: '2014-11-23 22:57:51'
tags:
- node-js
- windows-7
---


[Underscore-CLI](https://github.com/ddopson/underscore-cli "Underscore-CLI Website") is a great utility for working with JSON data. Below are the steps it took to get it running on my Windows 7 laptop:

1. Install [node.js](http://nodejs.org/ "node.js")1. Node adds a trailing \ to it’s path… to actually use it you must remove this as Windows does not want it to be there
2. Install [Python](https://www.python.org/ "python")
3. Add Python to your path (something like C:\Python27)
4. Underscore-CLI uses node-gyp… to get that to work on Windows 7 x64 you have to follow their guide at [https://github.com/TooTallNate/node-gyp/wiki/Visual-Studio-2010-Setup](https://github.com/TooTallNate/node-gyp/wiki/Visual-Studio-2010-Setup "vs2010setup"). Be sure to pay attention to the part about utilizing the Windows 7 SDK command prompt.


