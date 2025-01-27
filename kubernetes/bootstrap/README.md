# Cluster Bootstrap

The cluster bootstrapping process is made of 3 parts:

1. Installing Talos onto the cluster node
2. Bootstarpping Kubernetes on the Talos Cluster
3. Installing Flux and other prerequisites onto the cluster



## Getting Started

TL;DR:

```bash
talhelper genconfig
talhelper gencommand apply --extra-flags --insecure | bash
talhelper gencommand bootstrap | bash
talhelper gencommand kubeconfig --extra-flags="./clusterconfig/kubeconfig" | bash
```

### Installing Talos

I am installing Talos via `talhelper`, a utility tool to generate both Talos config files and some of those lengthy commands.

The main config file is found in [talconfig.yaml](./talos/talconfig.yaml). We need to generate the per-node talos config files using `talhelper genconfig`:

```bash
kubernetes/bootstrap/talos on  main [!?⇡] 
❯ talhelper genconfig
generated config for hkc-01.k8s.h.mirceanton.com in ./clusterconfig/home-cluster-hkc-01.k8s.h.mirceanton.com.yaml
generated config for hkc-02.k8s.h.mirceanton.com in ./clusterconfig/home-cluster-hkc-02.k8s.h.mirceanton.com.yaml
generated config for hkc-03.k8s.h.mirceanton.com in ./clusterconfig/home-cluster-hkc-03.k8s.h.mirceanton.com.yaml
generated client config in ./clusterconfig/talosconfig
generated .gitignore file in ./clusterconfig/.gitignore

```

Once the config is generated, we need to apply each generated file to the appropriate node. We can either do that manually, by running the `talosctl apply` command with the required flags, or we can just generate all of the commands using `talhelper gencommand apply --extra-flags=--insecure` and pipe that to `bash`:

```bash
kubernetes/bootstrap/talos on  main [!?⇡] 
❯ talhelper gencommand apply --extra-flags --insecure | bash

kubernetes/bootstrap/talos on  main [!?⇡] 
```

At this point, Talos is getting installed onto the nodes.

### Bootstrapping Kubernetes

Once Talos gets installed, it will start waiting for the `etcd` cluster to be up. We can start that process by running the `talosctl bootstrap` command against one of our controlplane nodes, or we can generate that command, again, using `talhelper gencommand boostrap` and pipe it to `bash`:

```bash
kubernetes/bootstrap/talos on  main [!?⇡] 
❯ talhelper gencommand bootstrap | bash

kubernetes/bootstrap/talos on  main [!?⇡] 
```

Give it a few moments to settle and then fetch the `kubeconfig` from the cluster:

```bash
kubernetes/bootstrap/talos on  main [!?⇡] 
❯ talhelper gencommand kubeconfig --extra-flags="./clusterconfig/kubeconfig" | bash

kubernetes/bootstrap/talos on  main [!?⇡] 
❯ export KUBECONFIG=./clusterconfig/kubeconfig
```
