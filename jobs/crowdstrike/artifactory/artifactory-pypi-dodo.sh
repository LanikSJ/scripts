#!/usr/bin/env bash

python3 -m pip install --index-url https://artifactory-internal-edge.dodo.eyrie.cloud/artifactory/api/pypi/ext-pypi-remote/simple docker
pip uninstall -y charset-normalizer docker idna requests urllib3
python3 -m pip install --index-url https://artifactory-internal-edge.dodo.eyrie.cloud/artifactory/api/pypi/ext-pypi-remote/simple docker
pip uninstall -y charset-normalizer docker idna requests urllib3
docker pull artifactory-k8s.dodo.eyrie.cloud/ext-registry-k8s-io-remote/etcd:3.5.10-0
docker system prune -af
docker pull artifactory-internal-edge.dodo.eyrie.cloud/ext-registry-k8s-io-remote/etcd:3.5.10-0
docker system prune -af
