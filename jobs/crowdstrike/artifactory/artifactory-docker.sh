#!/usr/bin/env bash

# Alpine Ironbank 
docker pull artifactory-internal-util.laggar.eagle.eyrie.cloud/techops-cicd-federal-docker-prod-local/ironbank/opensource/alpinelinux/alpine:20240109
docker pull artifactory-internal-util.merlin.eyrie.cloud/techops-cicd-federal-docker-prod-local/ironbank/opensource/alpinelinux/alpine:20240109

# Ivan Agent / Falcon Image Analyzer
docker pull registry.laggar.gcw.crowdstrike.com/falcon-imageanalyzer/gov-1/stage/falcon-imageanalyzer:1.0.8
docker pull registry.us-gov-2.crowdstrike.mil/falcon-imageanalyzer/gov-2/stage/falcon-imageanalyzer:1.0.8
docker pull registry.laggar.gcw.crowdstrike.com/falcon-imageanalyzer/gov-1/stage/falcon-imageanalyzer:1.0.9
docker pull registry.us-gov-2.crowdstrike.mil/falcon-imageanalyzer/gov-2/stage/falcon-imageanalyzer:1.0.9

# CSPM / k8s Protection
docker pull registry.laggar.gcw.crowdstrike.com/kubernetes_protection/kpagent:0.1473.0
docker pull registry.us-gov-2.crowdstrike.mil/kubernetes_protection/kpagent:0.1473.0
docker pull registry.laggar.gcw.crowdstrike.com/kubernetes_protection/kpagent:0.1854.0
docker pull registry.us-gov-2.crowdstrike.mil/kubernetes_protection/kpagent:0.1854.0

# Falcon Snapshot
docker pull registry.us-gov-2.crowdstrike.mil/falcon-snapshot/gov-2/release/cs-snapshotscanner:0.21.0
docker pull registry.laggar.gcw.crowdstrike.com/falcon-snapshot/gov-1/release/cs-snapshotscanner:0.21.0
