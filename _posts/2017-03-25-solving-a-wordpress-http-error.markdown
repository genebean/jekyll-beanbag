---
title: Solving a WordPress 'http error'
date: '2017-03-25 02:47:53'
---

Tonight we were trying to make the first post on my wife's blog and ran smack into a "Http error" message. When I looked in the console of my web browser I found an error 413 (Request Entity Too Large) message. After a bit of Googling it turns out that Nginx was the culprit. Apparently the default value of [`client_max_body_size`][cmbs] is 1 meg. As I am sure you can imagine, most images grabbed with a camera phone are larger than that now.

The solution was to add `client_max_body_size 1024M;` to my Nginx config. I picked the size for this setting so that it matched what I put in my `php.ini` file. Speaking of my PHP config, I am using PHP 7 and added the modified these settings:

```
upload_max_filesize = 1024M
post_max_size = 1024M
memory_limit = 1024M
max_execution_time = 180
```

Lastly, in case anyone reading this is wondering how Nginx fits into a WordPress install, its actually being used as a proxy for Apache (among other things).


[cmbs]:https://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size