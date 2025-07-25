#!/usr/bin/env bash
# This script will go through all BitBucket repos and update them

# Variables
export bitdir="$HOME/BitBucket/Mobile/"

echo && echo "Updating BitBucket Repos"

export repo=$(ls -lh $bitdir |grep drwx |awk '{print $NF}' |grep ardemo)
echo && echo "Updating $repo" && cd $bitdir/$repo && git remote prune origin && git checkout dev && git pull && sleep 5

export repo=$(ls -lh $bitdir |grep drwx |awk '{print $NF}' |grep cx-jenkins)
echo && echo "Updating $repo" && cd $bitdir/$repo && git remote prune origin && git checkout main && git pull && sleep 5

export repolist=$(ls -lh $bitdir |grep drwx |awk '{print $NF}' |grep iot)
for i in $repolist; do
  echo && echo "Updating $i" && cd $bitdir/$i && git remote prune origin && git checkout develop && git pull && sleep 5
done

export exclude="ardemo|cx-jenkins|iot-mobile-app|iot-puck"
export repolist=$(ls -lh $bitdir |grep drwx |awk '{print $NF}' |grep -Ev $exclude)

for i in $repolist; do
  echo && echo "Updating $i" && cd $bitdir/$i && git remote prune origin && git checkout master && git pull && sleep 5
done

cd ~
