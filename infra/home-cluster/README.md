# Home Cluster

This directory holds the Talos cluster configuration as well as the minimal kubernetes manifests required in order to deploy a fully functional Kubernetes cluster and sync it to this repository.

## Bootstrap

### Automated end-to-end

```bash
task cluster
```

### Automated "manual"

1. see the [talos directory](./talos/) to create the talos cluster
2. see the [kubernetes directory](./kubernetes/) to bootstrap kubernetes and sync it to this repo
