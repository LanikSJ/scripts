#!/usr/bin/env bash
# This script will go through all GitHub repos and update them

export GHE="/Users/ierenstein/GitHub/Move/"

if [[ `ifconfig |grep inet |grep 10.238` || `ifconfig |grep inet |grep 192.168` ]]; then
  export ORG=ITOps ; echo && echo "Update $ORG GHE Repos"
  for i in $(ls -lh $GHE/$ORG/ |grep drwx |awk '{print $NF}')
  do
    echo && echo "Updating $i" && cd $GHE/$ORG/$i && git checkout master && git pull
  done

  export ORG=GlobalDevOps; echo && echo "Update $ORG GHE Repos"
  for i in $(ls -lh $GHE/$ORG/ |grep drwx |awk '{print $NF}')
  do
    echo && echo "Updating $i" && cd $GHE/$ORG/$i && git checkout master && git pull
  done

  export ORG=InnerOpenSource; echo && echo "Update $ORG GHE Repos"
  for i in $(ls -lh $GHE/$ORG/ |grep drwx |awk '{print $NF}')
  do
    echo && echo "Updating $i" && cd $GHE/$ORG/$i && git checkout master && git pull
  done

  export ORG=ProSoft; echo && echo "Update $ORG GHE Repos"
  for i in $(ls -lh $GHE/$ORG/ |grep drwx |awk '{print $NF}')
  do
    echo && echo "Updating $i" && cd $GHE/$ORG/$i && git checkout master && git pull
  done
else
  echo && echo "Please login to VPN or connect to Office Network!"
fi
cd $HOME
