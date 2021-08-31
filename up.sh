#!/usr/bin/env bash

set -euo pipefail

####################################################
# start kind cluster
####################################################

KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-cluster-flux}
kind get clusters | grep "^${KIND_CLUSTER_NAME}$" > /dev/null || \
    kind create cluster --name="${KIND_CLUSTER_NAME}"

LB_IP=$(docker network inspect kind -f "{{with index .IPAM.Config 0}}{{.Subnet}}{{end}}" | cut -d. -f1-2).100.0
export LB_IP

####################################################
# install metallb
####################################################

helm repo add metallb https://metallb.github.io/metallb
helm repo up
cat <<EOF > /tmp/values.yaml
configInline:
  address-pools:
     - name: default
       protocol: layer2
       addresses:
         - ${LB_IP}/24
EOF
helm upgrade --install metallb metallb/metallb -f /tmp/values.yaml

####################################################
# install cert-manager
####################################################

helm repo add jetstack https://charts.jetstack.io
helm repo up
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.5.3 \
  --set installCRDs=true

####################################################
# create CA secret with public/private keypair
####################################################

kubectl -n cert-manager get secret ca-key-pair ||
    (openssl genrsa -out ca.key 2048
    openssl req -x509 -new -nodes -key ca.key -subj "/CN=Cluster Flux CA" -days 3650 \
        -reqexts v3_req \
        -extensions v3_ca \
        -out ca.crt
    kubectl create secret tls ca-key-pair \
        --cert=ca.crt \
        --key=ca.key \
        --namespace=cert-manager)

####################################################
# create ClusterIssuer
####################################################

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: ca-key-pair
EOF

####################################################
# install ingress controller
####################################################

helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm upgrade --install traefik traefik/traefik --set ports.websecure.tls.enabled=true

####################################################
# start and configure Git server
####################################################

for i in git-ingress.yaml git-ingress-cert.yaml ; do
    envsubst < "${i}" | kubectl apply -f -
done
kubectl apply -f git-serverstransport.yaml \
    -f gitserver.yaml \
    -f git-svc-cert.yaml

####################################################
# Bootstrap Flux
####################################################

FLUX_BIN=${FLUX_BIN:-flux}
${FLUX_BIN} bootstrap git \
    --password=git123 \
    --username=git \
    --url=https://git."${LB_IP}".sslip.io/repo \
    --path=flux \
    --ca-file="./ca.crt" \
    --token-auth
