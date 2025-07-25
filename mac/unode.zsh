#!/usr/bin/env zsh
# This script will update Node Modules

export NPM="$HOMEBREW_PREFIX/lib/node_modules"
echo && echo "Updating NPM Global"
npm update -g

for i in $(ls -lh $NPM |grep -v adguard |grep drwx |awk '{print $NF}')
do
  echo && echo "Updating $i" && cd $NPM/$i && npm update
done

echo && echo "Updating AGLint" && cd $NPM/@adguard/aglint && npm update
