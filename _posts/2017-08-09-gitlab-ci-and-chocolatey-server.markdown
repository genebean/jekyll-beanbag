---
title: GitLab CI and Chocolatey Server
date: '2017-08-09 13:15:20'
tags:
- chocolatey
- gitlab-2
---

If you are not familiar with [chocolatey](https://chocolatey.org/), its an awesome package manager, like `apt` or `yum`, for Windows. You can also host your own [internal chocolatey feed](https://github.com/chocolatey/choco/wiki/How-To-Host-Feed) and there is even a [Puppet module](https://forge.puppet.com/chocolatey/chocolatey_server) to build it for you. This can be especially useful for machines that cannot reach out to the internet to perform the installations. Chocolatey even provides a [step-by-step guide](https://chocolatey.org/docs/how-to-recompile-packages) on how to internalize packages, this can be a lot of manual steps from building packages, to getting them up to the Chocolatey server, keeping history, and maintaining when there are package updates.


This is why I created a quick solution for maintaining your package history in Git and using GitLab CI to automate building and deploying packages to your internal Chocolatey server. This guide assumes you have an internal GitLab instance, an internal Chocolatey server, and a Windows based GitLab Runner with powershell execution. Documentation [here](https://docs.gitlab.com/runner/) on GitLab Runners

## Setup

Before getting started I must note that, due to limitations of the Chocolatey API, it is required to store a service account's plain text credentials in the GitLab repo to fully automate this process. I will explain this limitation later. For this reason, create a user account on the Chocolatey server, just for this purpose, and assign least privilege. It is sufficient to add this user to the `Remote Management Users` group and grant the user permissions to the top level installation directory, in my case it was `C:\tools`.

First, create a private internal GitLab repository, then for all packages you wish to host internally follow steps 1 - 8 of the [recompile packages guide](https://chocolatey.org/docs/how-to-recompile-packages) to internalize packages and drop them in your repository (without version number in the directory name) so your repo structure looks something like the following example:

```bash
.
├── puppet-agent
│   ├── puppet-agent.nuspec
│   └── tools
│       └── chocolateyinstall.ps1
└── zabbix-agent
    ├── tools
    │   ├── chocolateyInstall.ps1
    │   └── chocolateyUninstall.ps1
    └── zabbix-agent.nuspec
```

Next, in your Gitlab repo create the file `.gitlab-ci.yml` and add the following contents, modifying it  for your environment:

```bash
before_script:
  - '$package_directories = get-childitem ${CI_PROJECT_DIR} -Directory'
  - '$password = ConvertTo-SecureString "PASSWORD" -AsPlainText -Force'
  - '$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist DOMAIN\USERNAME, $password'
  - '$choco_server = "chocolatey.localdomain"'

choco_deploy:
  script:
    # Change to each directory in this repo and build the package.
    - 'foreach ($directory in $package_directories) { $package_nuspec = get-childitem ${CI_PROJECT_DIR}/$directory *.nuspec -Name; cd ${CI_PROJECT_DIR}/$directory; choco pack ${CI_PROJECT_DIR}/$directory/$package_nuspec }'
    # List and delete all existing packages from the Chocolatey server via remote powershell.
    - 'Invoke-Command -ComputerName $choco_server -ScriptBlock {get-childitem C:\tools\chocolatey.server\App_Data\Packages -include *.nupkg -recurse | foreach ($_) {write-host "Removing package $_"; remove-item $_.fullname -force} } -credential $credentials'
    # Push each package to the Chocolatey server via the API.
    - 'foreach ($directory in $package_directories) { $package_nupkg = get-childitem ${CI_PROJECT_DIR}/$directory *.nupkg -Name; choco push ${CI_PROJECT_DIR}/$directory/$package_nupkg --source="http://chocolatey.localdomain/" --api-key="CHOCOLATEYKEY" --force}'
  tags:
    - powershell
```

Lets break this down a little.

### before_script

`$package_directories = get-childitem ${CI_PROJECT_DIR} -Directory`

This stores each directory name in your repo in a variable.

`$password = ConvertTo-SecureString "PASSWORD" -AsPlainText -Force`

This stores the service account password in a variable. I will note that though you _can_ convert the password from a secure string to an encrypted string using the `ConvertFrom-SecureString` cmdlet, BUT since the encrypted string will not be used on the same machine under the same user account, then you would have to pass the `-key` option, which in that case would simply give you a false sense of security by obfuscating the password and not really protecting it. Moving on.

`$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist DOMAIN\USERNAME, $password`

This creates a credential object and stores it in a variable.

`$choco_server = "chocolatey.localdomain"`

This stores your internal Chocolatey server in a variable.

### choco_deploy

This task performs 3 things to complete the deployment process. Build the package. Delete all current packages from the Chocolatey server. Push the newly built packages.

As far as I know the Chocolatey API does not allow for deleting or overwriting packages, so if you attempt to push a package/version that already exists, then the push will fail. The best solution I have found at the moment is to use remote powershell to delete all existing packages.

#### Build Packages

`foreach ($directory in $package_directories)`

Loop through each package directory and do a thing.

`{ $package_nuspec = get-childitem ${CI_PROJECT_DIR}/$directory *.nuspec -Name;`

In the current package directory, find the thing that end in `.nuspec` and store in a variable.

`cd ${CI_PROJECT_DIR}/$directory;`

Change to the current package directory

`choco pack ${CI_PROJECT_DIR}/$directory/$package_nuspec }`

Run `choco pack` on the nuspec file to build the package.


#### Delete existing packages

`Invoke-Command -ComputerName $choco_server -ScriptBlock`

Run the following remote powershell command on your Chocolatey server.

`{get-childitem C:\tools\chocolatey.server\App_Data\Packages -include *.nupkg -recurse`

Find all existing packages on the Chocolatey server.

`| foreach ($_) {write-host "Removing package $_"; remove-item $_.fullname -force} } -credential $credentials`

Pipe the packages to a for each loop and print what packages are being deleted, then actually delete them with passes credentials.

#### Push Packages

`foreach ($directory in $package_directories)`

Yet again, loop through each package directory and do a thing.

`{ $package_nupkg = get-childitem ${CI_PROJECT_DIR}/$directory *.nupkg -Name;`

In the current package directory, find the thing that end in `.nupkg` and store in a variable.

`choco push ${CI_PROJECT_DIR}/$directory/$package_nupkg --source="http://chocolatey.localdomain/" --api-key="CHOCOLATEYKEY" --force}`

Finally, push each package to the Chocolatey server using the API key and add the force option if your are not using HTTPS.


### Final Product

Long story short, now all your team must do to maintain internal packages is follow 5 simple steps:

1. Clone this repository to your computer.
1. Create a new branch to make your changes.
1. If the package does not yet exist in this repo, follow the [recompiling guide](https://github.com/chocolatey/choco/wiki/How-To-Recompile-Packages#how-to-internalizerecompile-an-existing-package-manually), but skip steps 9 and 10, then copy the entire directory to the root of this repo. If the package already exists, then simply modify `chocolateyInstall.ps1` as needed.
1. Copy the MSI or relavent install files to `C:\tools\chocolatey.server\Installers\{PACKAGE_DIRECTORY}\{INSTALLER}` on the Chocolatey server.
1. Finally, either create a pull request or just merge into master and push.