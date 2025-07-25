#!/usr/bin/env bash
# Download Artifactory Release and Scan with Ivan
# Usage: ./script
# shellcheck disable=SC2181,SC2236

DATE=$(date +"%Y%m%d")
TARGET_DIR="$HOME/Drive-Gov/Artifactory/Scan"
ART_VER=$(curl -X GET "https://releases-docker.jfrog.io/artifactory/api/search/latestVersion?g=org.artifactory.pro.docker&a=jfrog-artifactory-pro" |xargs)

if colima status; then
  echo && echo "Colima Already Running!"
else
  colima start
fi

echo && echo "Latest Version: $ART_VER " && echo

docker pull ext-jfrog-docker.artifactory.cicd.dc/jfrog/artifactory-pro:"$ART_VER"
if [[ $? != "0" ]]; then
  echo && echo "Docker Container Pull Failed!" && exit 1
fi

mkdir -p "$TARGET_DIR"/"$ART_VER"

echo && echo "Running Ivan ..."
ivan -region us-1 -image ext-jfrog-docker.artifactory.cicd.dc/jfrog/artifactory-pro:"$ART_VER" > "$TARGET_DIR"/"$ART_VER"/artifactory-pro-"$ART_VER"-"$DATE".json

echo && echo "Parsing for CVEs ..."
< "$TARGET_DIR"/"$ART_VER"/artifactory-pro-"$ART_VER"-"$DATE".json jq -r '.vulnerabilities.[].CVEID' \
  | sort -d > "$TARGET_DIR"/"$ART_VER"/artifactory-pro-"$ART_VER"-"$DATE".txt
echo "Done!"

echo && echo "Prunning old Images ..."  && echo
docker system prune -af && echo

if colima status; then
  colima stop
fi
