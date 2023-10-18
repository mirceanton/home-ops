# TrueNAS Cluster | Talos Cluster

This directory holds:

- the sops-encrypted secret bundle needed to generate the Talos machineconfig files for my cluster
- cluster-level configuration patches in `patches/`

## TL;DR

- To automatically bootstrap the Talos cluster and then Kubernetes on top of that and import the kubeconfig file:

    ```bash
    task truenas:cluster:create
    ```

- To reset the Talos cluster back to the original state:

    ```bash
    task truenas:cluster:reset
    ```
