#!/usr/bin/env bash

kind create cluster

function seed_images() {
    for image in $(cat images.txt) ; do
        docker pull ${image}
        kind load docker-image ${image}
    done
}

seed_images

flux install

flux create source helm bitnami --url=https://charts.bitnami.com/bitnami --interval=10m
flux create source helm mesosphere-staging --url=https://mesosphere.github.io/charts/staging --interval=10m
flux create source helm mesosphere-stable --url=https://mesosphere.github.io/charts/stable --interval=10m
flux create source helm kubernetes-dashboard --url=https://kubernetes.github.io/dashboard/ --interval=10m

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

flux create helmrelease traefik-forward-auth --source HelmRepository/mesosphere-staging --chart=traefik-forward-auth --release-name=traefik-forward-auth-kubeaddons --target-namespace=kubeaddons --values=traefik-forward-auth.yaml --depends-on=cert-manager --chart-version=0.2.14

flux create helmrelease dashboard --source HelmRepository/kubernetes-dashboard --chart=kubernetes-dashboard --release-name=dashboard-kubeaddons --target-namespace=kubeaddons --values=dashboard.yaml --chart-version=2.8.2
