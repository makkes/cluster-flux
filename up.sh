#!/usr/bin/env bash

kind create cluster --config=kind-config.yaml

function seed_images() {
    for image in $(cat images.txt) ; do
        docker pull ${image}
        kind load docker-image ${image}
    done
}

#seed_images

flux install

kubectl apply -f source.yaml -f stable-kustomization.yaml
