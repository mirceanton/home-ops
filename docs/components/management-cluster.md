# Management Cluster

## Software Prerequisites

Static DHCP reservations for the nodes as follows:

- 10.0.10.10 -> unassignable, will be the VIP for the controlplane nodes
- 10.0.10.11 -> controlplane node 1
- 10.0.10.12 -> controlplane node 1
- 10.0.10.13 -> controlplane node 1
- 10.0.10.14 -> unassignable, will be the VIP for the ingress controller

## How to Deploy

1. Flash talos onto the disks
2. Bootstrap the cluster

    ```bash
    task mkc:talos:bootstrap
    ```

3. Profit???

## Workloads Deployed

- MetalLB
- Ingress NGINX
- Cert Manager
- Rancher
- Homer Dashboard
- Github ARC (Actions Runner Controller) - autoscaling
