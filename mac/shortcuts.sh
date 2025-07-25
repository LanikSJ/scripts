#!/usr/bin/env bash
# This script will create my shortcuts in home directory
# shellcheck disable=SC2010,SC2155

if [[ $PWD != "$HOME" ]]; then
  cd "$HOME" || exit; echo "Back to $HOME directory you go!"
fi

export LINKS_COM=$(ls -alh ~/GitLab/Lanik/mac-shell/ |grep -v mac |grep lrwx |awk '{print $10}')
export LINKS_MAC=$(ls -alh ~/GitLab/Lanik/mac-shell/ |grep -i mac |grep lrwx |awk '{print $10}')

echo && echo "First let's put all the Common shortcuts in ...."
for i in $LINKS_COM; do
  rm -rf "$i" && ln -sf Shell/"$i" .
done

echo && echo "Now let's fix the Mac-Only shortcuts ...."
for i in $LINKS_MAC; do
  rm -rf "$i" && ln -sf Shell/mac/"$i" .
done

echo && echo "Bob's your Uncle! "
