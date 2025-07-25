#!/usr/bin/env bash

cd ~/Downloads || exit
helm pull https://registry.laggar.gcw.crowdstrike.com/kpagent-helm/cs-k8s-protection-agent-0.69.3.tgz
sha1sum ~/Downloads/cs-k8s-protection-agent-0.69.3.tgz
rm -f ~/Downloads/cs-k8s-protection-agent-0.69.3.tgz
cd ~ || exit

cd ~/Downloads || exit
helm pull https://registry.us-gov-2.crowdstrike.mil/kpagent-helm/cs-k8s-protection-agent-0.69.3.tgz
sha1sum ~/Downloads/cs-k8s-protection-agent-0.69.3.tgz
rm -f ~/Downloads/cs-k8s-protection-agent-0.69.3.tgz
cd ~ || exit

