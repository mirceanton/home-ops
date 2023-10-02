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

2. Push the configuration to the nodes

    ```bash
    task talos:apply-config
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
