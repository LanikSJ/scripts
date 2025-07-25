#!/bin/bash

for i in $(aws --profile=eagle-sso ec2 describe-instances --query 'Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress' \
  --filters Name=instance-state-name,Values=running Name=tag:Name,Values=eagle-laggar-main-p-ext-edge --output text |xargs |tr ' ' '\n'); \
   do ssh "$i" sudo touch /var/tmp/chef.disabled; done

for i in $(aws --profile=merlin-sso ec2 describe-instances --query 'Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress' \
  --filters Name=instance-state-name,Values=running Name=tag:Name,Values=eagle-util-main-p-int-edge --output text |xargs |tr ' ' '\n'); \
  do ssh "$i" sudo touch /var/tmp/chef.disabled; done

for i in $(aws --profile=merlin-sso ec2 describe-instances --query 'Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress' \
  --filters Name=instance-state-name,Values=running Name=tag:Name,Values=merlin-emu-main-p-ext-edge --output text |xargs |tr ' ' '\n'); \
  do ssh "$i" sudo touch /var/tmp/chef.disabled; done

for i in $(aws --profile=merlin-sso ec2 describe-instances --query 'Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress' \
  --filters Name=instance-state-name,Values=running Name=tag:Name,Values=merlin-util-main-p-int-edge --output text |xargs |tr ' ' '\n'); \
  do ssh "$i" sudo touch /var/tmp/chef.disabled; done

for i in $(aws --profile=merlin-sso ec2 describe-instances --query 'Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress' \
  --filters Name=instance-state-name,Values=running Name=tag:Name,Values=merlin-util-main-p-art-jpd --output text |xargs |tr ' ' '\n'); \
  do ssh "$i" sudo touch /var/tmp/chef.disabled; done

rm -rf /var/tmp/chef.disabled
chef-client
apt-mark unhold jfrog-artifactory-pro
apt upgrade -y jfrog-artifactory-pro
apt-mark hold jfrog-artifactory-pro
systemctl start artifactory; tail -f -n1000 /var/opt/jfrog/artifactory/log/console.log
