#!/usr/bin/env bash

kind create cluster

function seed_images() {
    # flux
    docker pull ghcr.io/fluxcd/helm-controller:v0.2.0
    docker pull ghcr.io/fluxcd/kustomize-controller:v0.2.1
    docker pull ghcr.io/fluxcd/notification-controller:v0.2.1
    docker pull ghcr.io/fluxcd/source-controller:v0.2.1
    kind load docker-image ghcr.io/fluxcd/helm-controller:v0.2.0
    kind load docker-image ghcr.io/fluxcd/kustomize-controller:v0.2.1
    kind load docker-image ghcr.io/fluxcd/notification-controller:v0.2.1
    kind load docker-image ghcr.io/fluxcd/source-controller:v0.2.1

    # metallb
    docker pull docker.io/bitnami/metallb-speaker:0.9.5-debian-10-r4
    docker pull docker.io/bitnami/metallb-controller:0.9.5-debian-10-r5
    kind load docker-image docker.io/bitnami/metallb-speaker:0.9.5-debian-10-r4
    kind load docker-image docker.io/bitnami/metallb-controller:0.9.5-debian-10-r5

    # cert-manager
    docker pull bitnami/kubectl:1.18.8-debian-10-r15
    docker pull quay.io/jetstack/cert-manager-controller:v1.0.1
    docker pull quay.io/jetstack/cert-manager-cainjector:v1.0.1
    docker pull quay.io/jetstack/cert-manager-webhook:v1.0.1
    kind load docker-image bitnami/kubectl:1.18.8-debian-10-r15
    kind load docker-image quay.io/jetstack/cert-manager-controller:v1.0.1
    kind load docker-image quay.io/jetstack/cert-manager-cainjector:v1.0.1
    kind load docker-image quay.io/jetstack/cert-manager-webhook:v1.0.1

    # traefik
    docker pull mesosphere/kubeaddons-addon-initializer:v0.3.0
    docker pull traefik:1.7.24
    kind load docker-image mesosphere/kubeaddons-addon-initializer:v0.3.0
    kind load docker-image traefik:1.7.24

    # dex
    docker pull mesosphere/dex-controller:v0.6.5
    docker pull gcr.io/kubebuilder/kube-rbac-proxy:v0.4.0
    docker pull mesosphere/kubeaddons-addon-initializer:v0.2.12
    docker pull mesosphere/dex:v2.22.0-2-g3657-d2iq
    kind load docker-image mesosphere/dex-controller:v0.6.5
    kind load docker-image gcr.io/kubebuilder/kube-rbac-proxy:v0.4.0
    kind load docker-image mesosphere/kubeaddons-addon-initializer:v0.2.12
    kind load docker-image mesosphere/dex:v2.22.0-2-g3657-d2iq

    # traefik-forward-auth
    docker pull mesosphere/kubeaddons-addon-initializer:v0.2.9
    kind load docker-image mesosphere/kubeaddons-addon-initializer:v0.2.9
    docker pull mesosphere/traefik-forward-auth:2.0.5
    kind load docker-image mesosphere/traefik-forward-auth:2.0.5
}

seed_images

flux install

flux create source helm bitnami --url=https://charts.bitnami.com/bitnami --interval=10m
flux create source helm mesosphere-staging --url=https://mesosphere.github.io/charts/staging --interval=10m
flux create source helm mesosphere-stable --url=https://mesosphere.github.io/charts/stable --interval=10m

kubectl create ns metallb
flux create helmrelease metallb --source HelmRepository/bitnami --chart=metallb --release-name=metallb --target-namespace=metallb --values=metallb.yaml --chart-version=1.0.1

docker cp kind-control-plane:/etc/kubernetes/pki/ca.key .
docker cp kind-control-plane:/etc/kubernetes/pki/ca.crt .
kubectl create ns cert-manager
kubectl create secret tls kubernetes-root-ca -n cert-manager --cert=ca.crt --key=ca.key
rm ca.key ca.crt
flux create helmrelease cert-manager --source HelmRepository/mesosphere-staging --chart=cert-manager-setup --release-name=cert-manager --target-namespace=cert-manager --values=cert-manager.yaml --chart-version=0.2.3

kubectl create ns kubeaddons
flux create helmrelease traefik --source HelmRepository/mesosphere-staging --chart=traefik --release-name=traefik-kubeaddons --target-namespace=kubeaddons --values=traefik.yaml --depends-on=cert-manager --chart-version=1.88.0

kubectl create secret generic -n kubeaddons ops-portal-credentials --from-literal=username=max --from-literal=password=max123
kubectl create clusterrolebinding max --clusterrole=cluster-admin --user=max
flux create helmrelease dex --source HelmRepository/mesosphere-stable --chart=dex --release-name=dex-kubeaddons --target-namespace=kubeaddons --values=dex.yaml --depends-on=traefik --chart-version=2.9.0

flux create helmrelease traefik-forward-auth --source HelmRepository/mesosphere-staging --chart=traefik-forward-auth --release-name=traefik-forward-auth-kubeaddons --target-namespace=kubeaddons --values=traefik-forward-auth.yaml --depends-on=cert-manager
