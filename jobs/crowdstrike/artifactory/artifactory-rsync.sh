#!/usr/bin/env bash

echo && echo "Eagle..."
rsync -avpr --exclude 'secrets*' ~/BitBucket/TechOpsCICD/govcloud-jfrog-k8s-stack/clusters/ ~/BitBucket/GovCloud/Eagle/govcloud-jfrog-k8s-stack/clusters/
rsync -avpr --exclude 'secrets*' ~/BitBucket/TechOpsCICD/govcloud-jfrog-k8s-stack/services/ ~/BitBucket/GovCloud/Eagle/govcloud-jfrog-k8s-stack/services/

echo && echo "Merlin..."
rsync -avpr --exclude 'secrets*' ~/BitBucket/TechOpsCICD/govcloud-jfrog-k8s-stack/clusters/ ~/BitBucket/GovCloud/Merlin/govcloud-jfrog-k8s-stack/clusters/
rsync -avpr --exclude 'secrets*' ~/BitBucket/TechOpsCICD/govcloud-jfrog-k8s-stack/services/ ~/BitBucket/GovCloud/Merlin/govcloud-jfrog-k8s-stack/services/
