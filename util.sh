#!/usr/bin/env bash
clear
echo "Removing any previously built gem file..."
rm -vf iamspe*.gem
echo "Uninstalling any previously installed instance..."
gem uninstall iamspe
read -p "Press any key..."

clear
echo "Update dependencies..."
bundle
read -p "Press any key..."

clear
echo "Build new instance..."
gem build *.gemspec
echo "Install new instance..."
gem install iamspe-*.gem
read -p "Press any key..."

clear
echo "You may now use the gem!"
read -p "Press any key..."

