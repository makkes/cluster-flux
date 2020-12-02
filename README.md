# Konvoy Demo with Flux

This is a stripped-down version of [Konvoy](https://d2iq.com/products/konvoy), capable of spinning up a local Kubernetes cluster with [kind](https://kind.sigs.k8s.io) and loading up some of Konvoy's [default Addons](https://github.com/mesosphere/kubernetes-base-addons) with [Flux v2](https://toolkit.fluxcd.io/).

## Prerequisites

* Have [kind](https://kind.sigs.k8s.io) installed
* Have [Flux CLI v0.4.2](https://github.com/fluxcd/flux2/releases/tag/v0.4.2) installed
* Have [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) installed

This demo has only been tested on Linux. Expect to not being able to access the Traefik Dashboard from your browser when using macOS.

## Running

It's as simple as running

```
./up.sh
```

After that you should be able to access the Traefik Dashboard at https://172.18.255.1/ops/portal/traefik/dashboard/.
