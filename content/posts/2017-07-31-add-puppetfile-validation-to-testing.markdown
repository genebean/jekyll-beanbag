---
author: jake
---

This is a quick post about how to add validation of your `Puppetfile`, primarily if you are using the [control-repo](https://github.com/puppetlabs/control-repo) and r10k for deploying Puppet environments. This came about because I found myself entering incorrect syntax into this file on more than a one occasion. Additionally, there are no indications of any problem, even when importing environments in Foreman, so the only way to find out is by manually running r10k from the command line on the Puppet Server.


This assumes you are familiar with and already have puppet-rspec testing setup. If not, please see [Unit testing with rspec-puppet — for beginners](https://puppet.com/blog/unit-testing-rspec-puppet-for-beginners) to get started.

Here are the steps to get the validation going:

* Add `gem 'r10k', '>= 2.5.5'` to your `Gemfile`.
  * Note: I had to use version 2.5.5 or else I would encounter [Issue #659](https://github.com/puppetlabs/r10k/issues/659) when running the tests in Travis CI or GitLab CI, even though they would succeed locally.

* Add `sh "r10k puppetfile check Puppetfile" if File.file?('Puppetfile')` to a new or existing task in your `Rakefile`.


I am only a beginner Ruby user, so by all means I am open to improvements. Happy testing!