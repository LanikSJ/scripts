#!/usr/bin/env zsh
# This script will add and update Helm repositories.

set -e # Exit immediately if a command exits with a non-zero status.

printf "\n%s\n" "Removing All Helm Charts..."
for i in $(helm repo list | awk '{print $1}' | grep -vi name); do
  helm repo rm "$i"
done

printf "\n%s\n" "Adding New Helm Charts..."
helm repo add atlassian https://artifactory.cicd.dc/artifactory/ext-atlassian-helm-remote
helm repo add jenkins https://artifactory.cicd.dc/artifactory/ext-jenkins-helm-charts-remote/
helm repo add jfrog https://artifactory.cicd.dc/artifactory/ext-jfrog-helm-remote/

printf "\n%s\n" "Updating Helm Repositories..."
helm repo update
