#!/usr/bin/env bash

set -euo pipefail

ENV=${1:-stable}
KUSTOMIZATION="${ENV}-kustomization.yaml"
[ -f ${KUSTOMIZATION} ] || (echo "unknown environment '${ENV}'" && exit 1)

if [[ "${2:-}" == "kind" ]] ; then
    kind create cluster --config=kind-config.yaml
fi

kubectl apply -f flux.yaml
kubectl apply -f source.yaml -f "${KUSTOMIZATION}"
