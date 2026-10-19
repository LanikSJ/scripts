#!/bin/bash

cd ~/Downloads/ || exit
rm -rf ~/Downloads/firefox-26.0a1.en-US.linux-x86_64.tar.bz2
wget ftp://ftp.mozilla.org/pub/mozilla.org/firefox/nightly/latest-mozilla-central/firefox-26.0a1.en-US.linux-x86_64.tar.bz2
tar xvvjf ~/Downloads/firefox-26.0a1.en-US.linux-x86_64.tar.bz2 
sudo rsync --progress -avpr ~/Downloads/firefox/ /usr/lib64/nightly/
sudo chown -R root.root /usr/lib64/nightly/
rm -rf firefox* ; cd ~ || exit
