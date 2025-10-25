locals {
  talos_version    = "v1.7.0"
  talos_platform   = "nocloud"
  architecture     = "amd64"
  talos_extensions = ["qemu-guest-agent"]

  gateway = "10.0.0.1"
  cluster_name     = "home-ops"
  cluster_endpoint = "https://10.0.0.100:6443"
  controlplane_ips = [ "10.0.0.101", "10.0.0.102", "10.0.0.103" ]
  worker_ips = [ "10.0.0.105", "10.0.0.106", "10.0.0.107" ]

  pve_iso_datastore = "ceph-fs"
  pve_nodes         = ["pve01", "pve02", "pve03"]
}