#!/usr/bin/env bash
clear

rm -vf iamspe*.gem
yes | gem uninstall iamspe

bundle install

gem build *.gemspec
gem install iamspe-*.gem

clear
