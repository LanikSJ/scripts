#!/usr/bin/env zsh
# This script will add helm charts and update them

echo && echo "Removing All Helm Charts..."
for i in $(helm repo list |awk '{print $1}' |grep -vi name); do helm repo rm $i; done

echo && echo "Adding New Helm Charts..."
helm repo add atlassian https://artifactory.cicd.dc/artifactory/ext-atlassian-helm-remote
helm repo add jenkins https://artifactory.cicd.dc/artifactory/ext-jenkins-helm-charts-remote/
helm repo add jfrog https://artifactory.cicd.dc/artifactory/ext-jfrog-helm-remote/

echo && echo "Updating..."
helm repo update

