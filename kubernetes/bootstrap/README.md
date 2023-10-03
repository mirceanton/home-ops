# Home Cluster | Kubernetes Cluster

This directory contains the minimum required app deployments to get FluxCD up and running:

- `cilium-system/cilium`: we deploy Talos with no CNI by default
- `kube-system/coredns`: we disable the default coreDNS deployment because I want to schedule those pods on controlplane nodes
- `flux-system/flux`: wel... it's flux

## Bootstrapping Flux

To bootstrap FluxCD on the Kubernetes cluster simply run:

```bash
task hkc:k8s:core-components
```

Or manually by running `helmfile apply` in this directory
