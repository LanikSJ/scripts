#!/usr/bin/env bash

apt update && apt install -y gnupg curl && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/nodesource.gpg] https://artifactory-k8s.dodo.eyrie.cloud/artifactory/ext-nodesource-deb-remote/node_20.x nodistro main" > /etc/apt/sources.list.d/cs.apt.repo.nodejs.dodo.list && \
    curl -k -fsSL https://artifactory-k8s.dodo.eyrie.cloud/artifactory/ext-nodesource-deb-remote/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/nodesource.gpg && \
    apt update && \
    apt install nodejs -y && \
    apt -y full-upgrade && \
    apt -y autoremove --purge && \
    rm -Rvf /var/cache/apt/* && \
    rm -Rvf /var/lib/apt/* && \
    npm config set registry https://artifactory-k8s.dodo.eyrie.cloud/artifactory/api/npm/ext-npm-remote/
    npm install @salesforce/cli --global