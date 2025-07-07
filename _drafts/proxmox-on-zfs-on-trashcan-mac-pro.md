---
title: Install Proxmox on ZFS on the Mac Pro (Late 2013)
author: gene
---
This is a guide for how to dual boot macOS 12 "Monterey" and Proxmox on a trashcan Mac, aka the late 2013 cylinder Mac Pro. The Linux side starts out as Debian Bookworm on ZFS and is then converted to Proxmox. This magical union is brought together with rEFInd and ZFSBootMenu. The purpose of installing, and retaining, macOS is simply to facilitate firmware updates and diagnostics of the hardware. As such, two thirds of the disk will be dedicated to Proxmox.

## From Mac OS Maverics (version 10.9) to macOS 12 "Monterey"

1. Internet Recovery via Shift+Option+Command+R
2. Step through OS versions from https://support.apple.com/en-us/102662 and do all software updates available in each (not OS upgrades) prior to moving on to the next OS version:
   - Yosemite 10.10
   - El Capitan 10.11
   - Sierra 10.12
   - High Sierra 10.13
   - Mojave 10.14
   - Catalina 10.15
   - Big Sur 11
   - Monterey 12
3. Make bootable USB of macOS 12 "Monterey"
4. Download rEFInd installation tools and copy to a USB drive
5. Format and reinstall from the USB of macOS 12 "Monterey"
6. Disable SIP per https://developer.apple.com/documentation/security/disabling-and-enabling-system-integrity-protection (including the reboot)
7. Install rEFInd and reboot
8. Enable SIP per https://developer.apple.com/documentation/security/disabling-and-enabling-system-integrity-protection
9. Mostly follow https://www.dwarmstrong.org/debian-install-zfs/ to install Debian, but without the encryption and not wiping the drive
10. Setup ZFSBootMenu per https://docs.zfsbootmenu.org/en/v2.3.x/general/uefi-booting.html#id2
11. Run all Debian updates / upgrades
12. Install Proxmox per https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_12_Bookworm
13. Remove old kernel and possibly os prober
14. Create LACP bonded bridge
15. Add TrueNAS ZFS over iSCSI Plugin for Proxmox VE https://github.com/TheGrandWazoo/freenas-proxmox
16. Use TrueNAS as primary storage for Proxmox
17. Setup clustering and utilize a dedicated corosync NIC a la https://www.amazon.com/gp/product/B011K4RKFW/ or a USB one
18. Setup backups - native, ZFS, Veeam, or something
19. Setup a macOS VM
20. Setup NUT client for clean shutdowns on power failure
