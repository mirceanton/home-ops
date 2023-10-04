# Home Cluster | Talos Cluster

This directory holds:

- the sops-encrypted secret bundle needed to generate the Talos machineconfig files for my cluster
- cluster-level configuration patches in `patches/`
- node-level configuration patches in `nodes/`.

## TL;DR

- To automatically bootstrap the Talos cluster and then Kubernetes on top of that and import the kubeconfig file:

    ```bash
    task hkc:cluster:create
    ```

- To reset the Talos cluster back to the original state:

    ```bash
    task hkc:cluste:reset
    ```

## Bootstrapping the Cluster (manual)

1. Generate the Talos configuration

    ```bash
    task hkc:talos:generate-config
    ```

2. Push the configuration to the nodes

    ```bash
    task hkc:talos:apply-config
    ```

3. Import the rendered talosconfig file in `~/.talos/config`

    ```bash
    task hkc:talos:talosconfig
    ```

4. Wait for the `kubelet` to become healthy on all nodes

    ```bash
    task hkc:talos:wait
    ```

    At this point the Talos cluster should be up and running. Validate using:

    ```bash
    talosctl get members
    ```

5. Kick off the Kubernetes bootstrap process

    ```bash
    task hkc:k8s:bootstrap
    ```

6. Import the kubeconfig file from the cluster

    ```bash
    task hkc:k8s:kubeconfig
    ```

7. Wait for the Kubernetes cluster to be ready

    ```bash
    task hkc:k8s:wait
    ```

    At this point the Kubernetes cluster should be up and running. Validate using:

    ```bash
    kubectl get nodes
    ```
