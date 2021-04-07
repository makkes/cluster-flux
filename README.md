# Cluster management demo with Flux

This is a simple demo of spinning up a basic Kubernetes cluster with [kind](https://kind.sigs.k8s.io) and loading up some Helm charts with [Flux v2](https://toolkit.fluxcd.io/).

## Prerequisites

* [kind](https://kind.sigs.k8s.io)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Flux CLI](https://toolkit.fluxcd.io/get-started/#install-the-flux-cli)

This demo has only been tested on Linux.

## Running

```
./up.sh
```

After that you should be able to clone the git repository from the server running in the cluster:

```
git clone http://git:git123@172.18.255.1/repo.git
```
