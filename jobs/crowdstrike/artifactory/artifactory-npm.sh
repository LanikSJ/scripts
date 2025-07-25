#!/usr/bin/env bash

cd ~/Downloads || exit
# Eagle
npm install --no-fund --no-audit --no-cache --loglevel verbose chalk minimatch minimist mkdirp nan rimraf through hostile bunyan wrappy once split \
    --registry https://artifactory-internal-util.laggar.eagle.eyrie.cloud/artifactory/api/npm/npm-remote/
rm -rf node_modules package*

# Merlin
npm install --no-fund --no-audit --no-cache --loglevel verbose chalk minimatch minimist mkdirp nan rimraf through hostile bunyan wrappy once split \
    --registry https://artifactory-internal-util.merlin.eyrie.cloud/artifactory/api/npm/npm-remote/
rm -rf node_modules package*
cd ..
