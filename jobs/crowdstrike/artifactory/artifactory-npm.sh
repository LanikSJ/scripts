#!/usr/bin/env bash
set -e

cd ~/Downloads || exit

install_npm_dependencies() {
    local registry_url="$1"
    echo "Cleaning up existing node_modules and package files..."
    rm -rf node_modules package*

    echo "Installing npm dependencies from $registry_url..."
    npm install --no-fund --no-audit --no-cache --loglevel verbose \
        chalk minimatch minimist mkdirp nan rimraf through hostile bunyan wrappy once split \
        --registry "$registry_url"
}

# Eagle
install_npm_dependencies "https://artifactory-internal-util.laggar.eagle.eyrie.cloud/artifactory/api/npm/npm-remote/"

# Merlin
install_npm_dependencies "https://artifactory-internal-util.merlin.eyrie.cloud/artifactory/api/npm/npm-remote/"

cd ..
