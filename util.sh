#!/usr/bin/env bash
clear

rm -vf iamspe*.gem
yes | gem uninstall iamspe

bundle

gem build *.gemspec
gem install iamspe-*.gem

clear
