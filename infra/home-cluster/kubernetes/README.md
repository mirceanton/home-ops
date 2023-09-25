# Kubernetes Core Components

This directory holds the minimum requried components to get Kubernetes up and running with flux:

- cillium CNI
- core dns
- flux2

They are all deployed as helm charts using the [helmfile](helmfile) so that they can be adopted into flux after bootstrapping.

The `manifests/` directory holds the git repository source, the kustomization and the age keyfile secret needed to synchronize the cluster with the repo.

## Boostrapping kubernetes

0. Bootstrap the talos cluster

    see the [talos directory](infra/cluster/talos)

1. Start the kubernetes bootstrap process

    ```bash
    task k8s:bootstrap
    ```

2. Import the `kubeconfig` file

    ```absh
    task k8s:kubeconfig
    ```

3. Wait for all of the nodes to join the cluster

    ```bash
    task k8s:wait
    ```

    > **Note**: Since we disabled the CNI, the nodes will not reach a `Ready` state, so we are just waiting for the nodes to join the cluster

4. Install `cillium`, `coreDNS` and `flux2` using the helmfile and create the flux objects:
    
    ```bash
    task k8s:core-components
    ```

5. wait 😄
