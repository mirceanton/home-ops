# Home Cluster | Kubernetes Cluster

This directory contains the minimum required app deployments to get FluxCD up and running:

## Bootstrapping Flux

To bootstrap FluxCD on the Kubernetes cluster simply run:

```bash
task truenas:k8s:core-components
```

Or manually by running `helmfile apply` in this directory
