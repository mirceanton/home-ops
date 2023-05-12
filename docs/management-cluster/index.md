# Management Cluster

## Hardware Prerequisites

1. 1x 4Gb Raspberry Pi 4
2. 3x 2Gb Raspberry Pi 4
3. 4x external SSDs with Talos v1.4.2 flashed

## Software Prerequisites

Static DHCP reservations for the nodes as follows:

- 10.0.10.10 -> unassignable, will be the VIP for the controlplane nodes
- 10.0.10.11 -> controlplane node 1
- 10.0.10.15 -> unassignable, will be the VIP for the worker nodes
- 10.0.10.16 -> controlplane worker 2
- 10.0.10.17 -> controlplane worker 3
- 10.0.10.18 -> controlplane worker 4

## How to Deploy

1. Flash Talos on the SSDs for the Pis

2. Apply the custom machine-configs

    ```bash
    task mkc:talos:apply
    ```

3. Import the `talosconfig` file for subsequent `talosctl` commands

    ```bash
    task mkc:import:talosconfig
    ```

4. Bootstrap kubernetes onto the Talos cluster

    ```bash
    task mkc:talos:bootstrap
    ```

    > Note: This command may fail if the previous `apply` command has not yet finished the bootstrapping of Talos itself. If so, wait a bit and try again. You can use `talosctl dmesg -f` to see the logs from the controlplane node

5. Import the `kubeconfig` file for `kubectl` commands

    ```bash
    task mkc:import:kubeconfig
    ```

6. Wait for Kubernetes to be up and running

    ```bash
    kubectl get nodes
    ```

    > Note: you should wait only until all nodes are detected. They will not be "Ready" as we are not deploying any CNI

7. Upgrade the nodes in-place in order to apply the `iscsi` system extension

    ```bash
    task mkc:talos:upgrade
    ```

    > Node: this will upgrade the nodes one by one, so it may take a hot minute!
