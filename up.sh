#!/usr/bin/env bash

set -euo pipefail

kind create cluster
flux install
for manifest in manifests/*.yaml ; do
    kubectl apply -f "${manifest}"
done
