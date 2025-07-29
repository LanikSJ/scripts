#!/usr/bin/env bash
# shellcheck disable=SC1091

# Eagle
mkdir pypi_test
cd pypi_test || exit
python3 -m venv pypi_test
source pypi_test/bin/activate
python3 -m pip install --index-url https://artifactory-internal-util.laggar.eagle.eyrie.cloud/artifactory/api/pypi/ext-pypi-remote/simple charset-normalizer docker idna packaging requests urllib3
deactivate && rm -rf pypi_test

# Merlin
mkdir pypi_test
cd pypi_test || exit
python3 -m venv pypi_test
source pypi_test/bin/activate
python3 -m pip install --index-url https://artifactory-internal-util.laggar.eagle.eyrie.cloud/artifactory/api/pypi/ext-pypi-remote/simple charset-normalizer docker idna packaging requests urllib3
deactivate && rm -rf pypi_test
