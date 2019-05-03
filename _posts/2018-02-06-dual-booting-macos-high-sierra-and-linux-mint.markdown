---
title: Dual Booting macOS High Sierra and Linux Mint
date: '2018-02-06 05:43:11'
---

This is a step-by-step walkthrough for dual booting a MacBook Pro (Mid-2015 aka MacBookPro11,5) that already has macOS High Sierra on it with Linux Mint. The hard drive is formatted APFS and has File Vault turned on. 

Before beginning I suggest reading this entire post to see how involved it is or, at a minimum, read the known issues at the bottom.

#### Full Backup

Any time you start messing with the partitions of existing drives its a good idea to have a full backup you can fall back on as its really easy to have your drive become unbootable. One way to do this is to use [Carbon Copy Cloner](https://bombich.com/). It'll take care of backing up all your files along with the special partitions needed to make things work including the recovery partition. Be sure to put the backup on an external hard drive.

##### Formatting your external drive
When you go to format your external hard drive there are two things you need to be sure and do to have the best chance at success:

- In the top left of Disk Utility click the button above "View" and tell it to show all devices
- Select the drive, not one of the partitions on it
- When you "Erase" the disk be sure to pick "Mac OS Extended (Journaled)" regardless of how your internal drive is formatted.

Once your backup completes go into System Preferences and change the startup disk to the external drive and reboot. If your internal drive is encrypted you'll be prompted for its password when you login... don't enter it. By not entering your password you can ensure that everything you see is from the backup and not the internal one. Once you have verified everything looks good go into System Preference again, set the startup disk back to the internal drive, and reboot. Once the system comes back up eject the backup disk and sit it aside. Sitting it aside is especially important as that ensures you don't accidentally damage the the backup while installing Linux.

#### Tools

The next step is to download a few tool that will be used in subsequent steps:

- [Etcher](https://etcher.io) for creating a bootable USB drive.
- A [Linux Mint](https://linuxmint.com/download.php) ISO
- The [rEFInd](http://www.rodsbooks.com/refind/getting.html) binary zip file. Unzip this in your Downloads folder.

Once you have everything downloaded open up Etcher use it to put the Mint ISO onto a thumb drive.

#### Make room for Mint

The new [Apple File System (APFS)](https://en.wikipedia.org/wiki/Apple_File_System) has introduced some extra hurdles you have to jump through to be able to resize an existing partition. The new process looks like this:

1. Disable Time Machine automatic backups
2. Delete local Time Machine snapshots
3. Shrink your macOS install
4. Re-enable automatic backups

If you try and shrink your macOS partition without taking these extra steps you will likely run into unhelpful error message and a failed process. On the plus side, this can all be done easily from the terminal.

##### Disable Automatic Backups & Delete Snapshots

While your Time Machine disk isn't attached your machine will create and store some snapshots locally. These need to be deleted before you can shrink your partition. Open Terminal (or iTerm) and run the following commands:

```bash
# Disable automatic backups
╔ ☕️ genebean:~
╚ᐅ sudo tmutil disable

# List the snapshots
╔ ☕️ genebean:~
╚ᐅ tmutil listLocalSnapShots /

# Delete all the snapshots, 1 at a time:
╔ ☕️ genebean:~
╚ᐅ for snap in $(tmutil listLocalSnapShots / | \
cut -d '.' -f 4); do \
sudo tmutil deleteLocalSnapshots $snap; done

# Verify that all of the snapshots are gone:
╔ ☕️ genebean:~
╚ᐅ tmutil listLocalSnapShots /
```

Here's what all that looked like for me:

```bash
╔ ☕️ genebean:~
╚ᐅ sudo tmutil disable

╔ ☕️ genebean:~
╚ᐅ tmutil listLocalSnapShots /
com.apple.TimeMachine.2018-01-26-230115
com.apple.TimeMachine.2018-01-27-000451
com.apple.TimeMachine.2018-01-27-010032
com.apple.TimeMachine.2018-01-27-030027
com.apple.TimeMachine.2018-01-27-040022
com.apple.TimeMachine.2018-01-27-050314
com.apple.TimeMachine.2018-01-27-060259
com.apple.TimeMachine.2018-01-27-070017
com.apple.TimeMachine.2018-01-27-092621
com.apple.TimeMachine.2018-01-27-223433

╔ ☕️ genebean:~
╚ᐅ for snap in $(tmutil listLocalSnapShots / | \
cut -d '.' -f 4); do \
sudo tmutil deleteLocalSnapshots $snap; done
Deleted local snapshot '2018-01-26-230115'
Deleted local snapshot '2018-01-27-000451'
Deleted local snapshot '2018-01-27-010032'
Deleted local snapshot '2018-01-27-030027'
Deleted local snapshot '2018-01-27-040022'
Deleted local snapshot '2018-01-27-050314'
Deleted local snapshot '2018-01-27-060259'
Deleted local snapshot '2018-01-27-070017'
Deleted local snapshot '2018-01-27-092621'
Deleted local snapshot '2018-01-27-223433'

╔ ☕️ genebean:~
╚ᐅ tmutil listLocalSnapShots /
```

Credit for the steps above goes to https://www.imore.com/getting-apfs-resizing-errors-using-disk-utility-fix-may-help

##### Partitioning

Next is to make the partitions that will be used during the installation process. I'm starting with a 500G drive and am going to use 150G of it for Mint. I'm going to carve that 150G up into two partitions:

- a 2G one for `/boot`
- a 148G one for an encrypted `/`

macOS doesn't know anything about ext4 or other Linux filesystems so I am going to tell diskutil that these are FAT32 partitions.

Step one is to find the disk that macOS is installed on. This can be done in the terminal via `diskutil apfs list` but its way easier to just open Disk Utility, click on the drive where macOS is installed, and note the value next to `Device:` in the lower right. That value is `disk1s1` for me. In the next command we will use the `disk1` portion of that value.

Now that we have the disk name lets shrink macOS and make our new partitions.

```bash
╔ ☕️ genebean:~
╚ᐅ sudo diskutil apfs resizeContainer disk1 350g FAT32 LINUXBOOT 2g FAT32 LINUXROOT 0b
```

In the command above, `0b` translates to "however much space is left."

##### Re-enable Automatic Backups

Now that you have finished resizing your drive you can re-enable automatic updates with the following:

```bash
╔ ☕️ genebean:~
╚ᐅ sudo tmutil enable
```

#### Install Linux Mint

Now that all the prep work is done we can finally do what we initially set out to do... install Linux. Insert your thumb drive, reboot, and hold the option key. You should see your internal hard drive along with one that says EFI Boot... boot to the latter. Next you'll see a grub menu and then you'll boot into a live desktop environment. 

First things first, connect to a wireless network so that updates can be pulled in during the installation. Once connected, double click the installer. These are the choices I made during install:

- Continue for English
- Marked box for installing third-party software, Contine
- Something else on Installation type, continue
- Selected the 2G fat32 partition I created when resizing macOS. For me, this was `/dev/sda3`. Once selected:
  - I clicked "Change..."
  - Changed "Use as:" to ext4
  - Marked "Format the partition"
  - Set the mount point to `/boot`
  - Clicked OK (this may prompt you about having to write changes to disk... if so, agree)
- Selected the 148G fat32 partition. For me, this was `/dev/sda4`. Once selected:
  - I clicked "Change..."
  - Changed "Use as:" to physical volume for encryption
  - Entered a password to decrypt the disk with
  - Clicked OK
- Waited a moment or two while this did some work in the background
- Selected the new `/dev/mapper/sda4_crypt` entry nested under the top entry of the same name
  - I clicked "Change..."
  - Changed "Use as:" to ext4
  - Marked "Format the partition"
  - Set the mount point to `/`
  - Clicked OK
- Under "Device for boot loader installation" I chose my `/boot` partition: `/dev/sda3` (explanation below)
- Clicked "Install Now"
- Clicked "Continue" to ignore the swap warning. (we'll come back to this later)
- Reviewed the changes to my disk and clicked Continue
- Selected my time zone and clicked Continue
- Changed my keyboard layout to "English (US) - English (Macintosh), clicked Continue
- Created my use account and set the name of the computer, clicked Continue
- Waited for the install to finish...............

You may be wondering why I chose to put grub on `/dev/sda3` instead of `/dev/sda`. The answer is actually quite simple: I don't want to use grub as my bootloader for macOS nor do I want to take a chance of it hanging around if I decide to remove Mint later. rEFInd understands the Apple boot options better than grub does and is nicer to look at in my opinion... especially once themed. Additionally, if you were to want to adapt this entire process to triple booting with either a second Linux distro or Windows you would not have to worry about grub playing nice with that environment. In the case of a second Linux, each distro could also maintain its own set of grub entries and its own look and feel.

##### Rebooting

Once the install is complete you will be prompted to reboot or continue testing... the choice is yours. Once you do reboot you will be prompted to remove the thumb drive... do so but read the next section before hitting enter. If you have already hit enter you will likely have been booted into Mint... just read the next section then do the reboot like it talks about.

#### System Integrity Protection and rEFInd

System Integrity Protection, aka SIP, help protect important system files. Generally speaking, this is a very good thing. That said, when you want to do special things like install a boot manager, it means you have to take a couple of extra steps. I suggest that for this section you either open this article on a device other than the one you are working on or print it out as you're going to need it while the target computer is out of commission.

The first step is to reboot into recovery by holding Command+R (⌘+R) while rebooting. Once booted, open Disk Utility, click on where macOS is installed, then click the mount button in the row of icons at the top of Disk Utility. This will prompt you for your password and unlock the drive.

To disable SIP close Disk Utility and open Terminal from the Utilities menu and enter:

```bash
csrutil disable
```

Now you need to reboot so that SIP is fully disabled. Be sure to hold ⌘+R while rebooting so that you return to recovery mode.

##### rEFInd Installation

Once back in recovery mode its time to install rEFInd. First, repeat the steps above to mount and unlock your macOS drive. Once its unlocked return to Terminal. We now need to change into the folder created by downloading and unzipping rEFInd. First, run this command to list the drives we can cd into:

```bash
# Your output my be different than mine...
ls /Volumes/
Macintosh HD         OS X Base System
``` 

For me, macOS is installed on `Macintosh HD`, my user account on that drive is `genebean`, and I downloaded rEFInd 0.11.2. While building out the path to change into be sure to remember that tab completion is your friend... type a couple of letters, hit tab, and repeat until the path is complete. Enter this command substituting your values for the ones above and using tab completion:

```bash
cd /Volumes/Macintosh\ HD/Users/genebean/Downloads/refind-bin-0.11.2/
```

The next steps are to run the installer, re-enable SIP, and reboot. Do this by entering these commands:

```bash
./refind-install
csrutil enable
reboot
```

If all goes well then you will soon see your new boot manager with both an Ubuntu icon and an OS X icon. Choose the latter to make sure macOS is still okay and that no restore is needed. Assuming everything comes up okay you can reboot and choose the Ubuntu icon that will take you into Linux Mint.

#### First boot of Mint

##### 🐲 Microcode (dragons ahead) 🐲

If you've ever used Mint before or you just like to click things you may be tempted to go straight for the Driver Manager... this is fine, just __do not__ update the microcode... leave that task to macOS so as to not confuse updates for the hardware coming from Apple. Along those same lines, you should periodically boot to macOS and patch it so that any hardware updates get applied.

##### Update Manager

The first (or next) thing I recommend doing is opening Update Manager either by clicking the shield near the clock or from the application menu. It should prompt you for which update policy to use... I recommend the default of "Let me review sensitive updates." Once you pass that screen you will likely see a blue bar that asks if you want to switch to a local mirror... do that, let it sit a minute while it tests mirror speeds, and pick the one at the top of the list. Once you have your mirror picked out close that window then:

- refresh the list of updates
- install the new version of mint update
- refresh the list of updates
- review the resulting list, particularly the ones at the bottom that are unchecked
- click select all
- install updates
- reboot so the new kernel applies
- check one more time for updates (there shouldn't be any)

#### Known Issues

- Graphics need help... likely due to needing proprietary AMD drivers. Info to help install these [here](https://forums.linuxmint.com/viewtopic.php?t=229229)
- Brightness controls don't work. Likely due to ^^
- Right click via the trackpad doesn't work. [This](https://www.reddit.com/r/linuxmint/comments/4lqjxm/brightness_and_other_problems_on_macbook_pro/) reddit post says Cinnamon 3 fixes this... need to check that out.
- The same reddit post says to follow [this](https://www.pcsteps.com/858-kernel-upgrade-linux-mint-ubuntu/) guide to upgrade to a newer kernel.
- Getting keyboard shortcuts to act in Linux the same as in macOS is a real PITA...