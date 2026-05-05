---
author: gene
title: Automatically Generate GoAccess stats
---

I've been using [GoAccess](https://goaccess.io) to look at my logs for a while now. The other day I decided I wanted be able to look at these stats for the different sites on my web server in a variety of ways including:

* all data from all sites combined
* all data on a per-site basis
* daily stats from each site kept for a week

The thing with wanting daily stats is it helps if they are created in a way that only covers that day. That sounds simple, but the logrotate generally runs around around 3am. So what's the solution? Cron. To be more exact, run logrotate from cron and generate stats while you're at it. 

```bash
# Puppet Name: rotate nginx logs
0 0 * * * /root/updatestats.sh
```

Now, if you are going to run logrotate from cron you'd better turn of the original one. Here's how I did that:

```bash
$ cat /etc/logrotate.d/nginx
# this is managed by a cron job.
# the script that would normally be here is at /root/nginx-logroate.conf
```

You have to do something like this instead of just deleting the file because otherwise the next time there is an update to Nginx (or whatever web server you are running) it will just recreate the file. The reason this works is that installers generally don't clobber existing files. Below is the referenced replacement:

```bash
$ cat /root/nginx-logroate.conf
# use date as a suffix of the rotated file
dateext

/var/log/nginx/*log {
    create 0644 nginx nginx
    daily
    rotate 10
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        /bin/kill -USR1 `cat /run/nginx.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
```


#### updatestats.sh

This is the script where all the magic happens. Let's break it down to see what's going on. A copy of the full script will be at the end of this article in case you want to copy it.

```bash
day=`date --date yesterday +"%A" | tr '[:upper:]' '[:lower:]'`
```

The script runs at midnight which is just barely into the day after the logs that we are going to process. For that reason we need to determine what the day was yesterday. For example, when I ran `$ date --date yesterday +"%A"` it returned `Thursday`. Seeing as I want everything to be lower case I piped the output through `tr` to convert it. The end result is `thrusday`. This will be used as part of the file name for the daily logs.

```bash
date=`date +"%Y%m%d"`
```

Next we get the current date in year month day format which results in something like `20170616`.

```bash
gitcmd='git --git-dir=/storage/nginx/html/goaccess/.git/ --work-tree=/storage/nginx/html/goaccess/'
```

This one is a bit more interesting. When you run git from somewhere outside of the repository you have to tell it where to find its configuration ([git-dir](https://git-scm.com/docs/git)) and where the base of the repo is ([work-tree](https://git-scm.com/docs/git)). Adding in all that info makes for a long command so I've stashed it in a variable that I can refer to later.

```bash
# Create a backup of the dbs
tar -czvf /root/dbbackup-`date +"%Y%m%d-%H%M%S"`.tgz /storage/goaccess-dbs

# keep only the 5 newest backups (to keep x, pass x+1 to tail)
ls -tp /root/dbbackup-* | tail -n +6 | xargs -d '\n' rm -f --
```

Nest we take a backup of the databases GoAccess is using for the stats in case something goes haywire. Backup take a lot of space so after the new one is taken I prune out the old ones.

```bash
# Rotate logs
/sbin/logrotate -s /var/lib/logrotate/logrotate.status /root/nginx-logroate.conf
```

Remember the disabled logrotate from earlier? Well, this is where I run its replacement.

Now, before we move on to the next part I need to provide some context. As a byproduct of the way I have configured Nginx my logs are named like this after being rotated: 

* `access.log-20170616.gz`
* `beanbag.technicalissues.us.access.log-20170616.gz`

Keep this format in mind as you look through the next part and it will make more sense. Also remember the date variables from earlier.

```bash
# Process each newly rotated log
for log in `ls /var/log/nginx/*access.log-${date}.gz`; do
  echo "processing ${log}..."
  name=`echo ${log} | rev | cut -f1 -d '/' |rev | cut -f1 -d '.'`
```

I am going to pause right here and break down that `name=` bit. Lets assume `${log}` equals the `beanbag` log from above. Going on that assumption here is what each part of that line does:

```bash
$ echo ${log}
/var/log/nginx/beanbag.technicalissues.us.access.log-20170616.gz

$ echo ${log} |rev
zg.61607102-gol.ssecca.su.seussilacinhcet.gabnaeb/xnign/gol/rav/

$ echo ${log} | rev | cut -f1 -d '/'
zg.61607102-gol.ssecca.su.seussilacinhcet.gabnaeb

$ echo ${log} | rev | cut -f1 -d '/' |rev
beanbag.technicalissues.us.access.log-20170616.gz

$ echo ${log} | rev | cut -f1 -d '/' |rev | cut -f1 -d '.'
beanbag
```

As you can see, that chain of commands produces just the first part of each log's name which, in this case, is `beanbag`. This word is something that is unique to each set of logs which lets me easily correlate them with the associated site or function. By function I mean `access` or `redirects` which are special sets of logs I generate for non-site-specific functions within my `nginx.conf`. Now, lets get back to the script.

```bash
  processed_logs=''
```

This is kind of a storage bin... more on it in a moment.

```bash
  [ -d "/storage/goaccess-dbs/${name}" ] || mkdir -p "/storage/goaccess-dbs/${name}"
```

Here if the one-word name generated previously corresponds to a directory where all the GoAccess databases are kept I return true. If, on the other hand, it doesn't exist then it gets created.

```bash
  [ -s ${log} ] && zcat ${log} | /usr/bin/goaccess -o /storage/nginx/html/goaccess/${name}-${day}.html \
                && processed_logs="${processed_logs}/storage/nginx/html/goaccess/${name}-${day}.html "

  [ -s ${log} ] && zcat ${log} | /usr/bin/goaccess -o /storage/nginx/html/goaccess/${name}-overall.html --load-from-disk --keep-db-files --db-path=/storage/goaccess-dbs/${name}/ \
                && processed_logs="${processed_logs}/storage/nginx/html/goaccess/${name}-overall.html "

  [ -s ${log} ] && zcat ${log} | /usr/bin/goaccess -o /storage/nginx/html/goaccess/overall.html --load-from-disk --keep-db-files --db-path=/storage/goaccess-dbs/overall/ \
                && processed_logs="${processed_logs}/storage/nginx/html/goaccess/overall.html "
```

Now we finally get to generate some stats. `[ -s ${log} ]` verifies that the log file's size is not zero. Each command is prefixed with this so that the script doesn't error out as a result of an empty file. Here's a breakdown of what the three chunks of code above do assuming there is a non-zero-sized log file:

1. cat the gzipped log to `goaccess`, output the results to a file that is named something like `beanbag-thrusday.html`
2. add something like this to the end of the `processed_logs` variable: "/storage/nginx/html/goaccess/beanbag-thrusday.html " (note the space between the last character and the quote... that ensures each path ends up with a space between it and the next one.
3. cat the gzipped log to `goaccess`, output the results to a file that is named something like `beanbag-overall.html`. The last bit of this line loads up the database that tracks all the previous traffic to the site associated with this log.
4. add this new file's path to `processed_logs`
5. this is the same as #3 except its adding the stats to the database that includes all the sites. Those stats are stored in `overall.html`.
6. add this new file's path to `processed_logs`

```bash
  [ -s ${log} ] && ${gitcmd} add ${processed_logs}
```

Remember that storage bin called `processed_logs`? Here's why it exists. This line uses the really long git command stored in a variable at the top of the script to add all file paths in `processed_logs` to the git repo whose base is the directory the stats files are output to.

```bash
  [ -s ${log} ] && ${gitcmd} commit -m "Updated stats from ${name}" ${processed_logs}
done
```

This line takes all the new and/or changed files and does a `git commit` on them with a commit message that includes the site name of the stats that caused the update. Right after the git commit is the `done` marker that signifies the end of the for loop that processes all of the day's logs.

```bash
# Push to BitBucket
${gitcmd} push -u origin master
```

Since the part before this is happening inside a for loop there is generally one commit for each site, one for the access logs, and one for the redirect logs. This line takes all those new commits and pushes them to a private repository on BitBucket as a backup.

Remember I said that when running a commit from outside of the repository it could end up being a really long command? Well, here is an example of what the command for committing the files for the beanbag log would look like:

```
[ -s /var/log/nginx/beanbag.technicalissues.us.access.log-20170616.gz ] && git --git-dir=/storage/nginx/html/goaccess/.git/ --work-tree=/storage/nginx/html/goaccess/ commit -m "Updated stats from beanbag" /storage/nginx/html/goaccess/beanbag-thrusday.html /storage/nginx/html/goaccess/beanbag-overall.html /storage/nginx/html/goaccess/overall.html
```

That's a little unweildy when all the variable are expanded and much harder to read in my opinion.


#### Next Steps:

This setup has produced some really useful information but lacks a little polish when it comes to being able to review it. With that in mind I have a few tasks that I'd like to do in the coming months.

First, I'd like to prune parts of the dailies that aren't useful. For example, there are sections of the generated web page that don't have any useful data unless you are looking at multiple day's logs.

Second, I want to look into alternate display methods for the data. GoAccess makes a perfectly nice html web page but maybe I could tell it to generate JSON data instead, throw that into [MongoDB](https://www.mongodb.com/), and then display the data as part of a formatted, cohesive website instead of just having a bunch of standalone html pages.

Lastly, and honestly, this will probably happen first, I want to compare what I am getting from GoAccess to what [Piwik](https://piwik.org/) would give me.

#### The Entire `updatestats.sh` script

As promised, here is the script in its entirety.

```bash
day=`date --date yesterday +"%A" | tr '[:upper:]' '[:lower:]'`
date=`date +"%Y%m%d"`
gitcmd='git --git-dir=/storage/nginx/html/goaccess/.git/ --work-tree=/storage/nginx/html/goaccess/'

# Create a backup of the dbs
tar -czvf /root/dbbackup-`date +"%Y%m%d-%H%M%S"`.tgz /storage/goaccess-dbs

# keep only the 5 newest backups (to keep x, pass x+1 to tail)
ls -tp /root/dbbackup-* | tail -n +6 | xargs -d '\n' rm -f --

# Rotate logs
/sbin/logrotate -s /var/lib/logrotate/logrotate.status /root/nginx-logroate.conf

# Process each newly rotated log
for log in `ls /var/log/nginx/*access.log-${date}.gz`; do
  echo "processing ${log}..."
  name=`echo ${log} | rev | cut -f1 -d '/' |rev | cut -f1 -d '.'`
  processed_logs=''

  [ -d "/storage/goaccess-dbs/${name}" ] || mkdir -p "/storage/goaccess-dbs/${name}"

  [ -s ${log} ] && zcat ${log} | /usr/bin/goaccess -o /storage/nginx/html/goaccess/${name}-${day}.html \
                && processed_logs="${processed_logs}/storage/nginx/html/goaccess/${name}-${day}.html "

  [ -s ${log} ] && zcat ${log} | /usr/bin/goaccess -o /storage/nginx/html/goaccess/${name}-overall.html --load-from-disk --keep-db-files --db-path=/storage/goaccess-dbs/${name}/ \
                && processed_logs="${processed_logs}/storage/nginx/html/goaccess/${name}-overall.html "

  [ -s ${log} ] && zcat ${log} | /usr/bin/goaccess -o /storage/nginx/html/goaccess/overall.html --load-from-disk --keep-db-files --db-path=/storage/goaccess-dbs/overall/ \
                && processed_logs="${processed_logs}/storage/nginx/html/goaccess/overall.html "

  [ -s ${log} ] && ${gitcmd} add ${processed_logs}
  [ -s ${log} ] && ${gitcmd} commit -m "Updated stats from ${name}" ${processed_logs}
done

# Push to BitBucket
${gitcmd} push -u origin master
```