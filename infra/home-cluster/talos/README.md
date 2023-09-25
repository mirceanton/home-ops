# Talos Cluster

This directory holds:

- the sops-encrypted secret bundle needed to generate the Talos machineconfig files for my cluster
- cluster-level configuration patches in `patches/`
- node-level configuration patches in `nodes/`.

## Bootstrapping the Cluster

1. Generate the talos configuration

    ```bash
    task talos:generate-config
    ```

    > Note: this command will fail if a config is already generated. to fix that, run the `delete-config` task:
    > 
    > ```bash
    > task talosctl:delete-config
    > ```

    Or manually via:
    
    ```bash
    export CLUSTER_NAME=...
    export CLUSTER_ENDPOINT=...
    export KUBERNETES_VERSION=...

    talosctl gen config $CLUSTER_NAME https://$CLUSTER_ENDPOINT:6443 \
        --kubernetes-version $KUBERNETES_VERSION \
        --with-secrets secrets.yaml \
        --config-patch @patches/... \
        [...]
        --config-patch @nodes/... \
        [...]
        --output rendered/
    ```

    Then fix the `talosconfig` endpoints and nodes:

    ```bash
    talosctl --talosconfig rendered/talosconfig config endpoint 10.0.10.11 10.0.10.12 10.0.10.13
    talosctl --talosconfig rendered/talosconfig config node 10.0.10.11
    ```

2. Push the configuration to the nodes

    ```bash
    task talos:apply-config
    ```

    or manually via

    ```bash
    # Push config to controlplane nodes
    talosctl apply --insecure -f rendered/controlplane.yaml -n 10.0.10.11
    talosctl apply --insecure -f rendered/controlplane.yaml -n 10.0.10.12
    talosctl apply --insecure -f rendered/controlplane.yaml -n 10.0.10.13

    # Push config to worker nodes
    talosctl apply --insecure -f rendered/worker.yaml -n 10.0.10.21
    talosctl apply --insecure -f rendered/worker.yaml -n 10.0.10.22
    ```

3. Import the rendered talosconfig file in `~/.talos/config`

    ```bash
    task talos:talosconfig
    ```

4. Wait for the `kubelet` to become healthy on all nodes

    ```bash
    task talos:wait
    ```

At this point the talos cluster should be up and running. Validate using:

```bash
talosctl get members
```

To move on to the kubernetes bootstrap process, see the `infra/cluster/kubernetes/` directory.
