#!/usr/bin/env bash
set -e # halt script on error

bundle exec jekyll build
bundle exec htmlproofer --assume-extension --check-favicon --check-opengraph --report-invalid-tags --url_swap "\/jekyll-beanbag:" --url-ignore "#" --disable_external --empty_alt_ignore ./_site
