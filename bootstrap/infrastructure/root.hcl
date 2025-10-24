locals {
  talos_version    = "v1.10.7"
  talos_platform   = "nocloud"
  architecture     = "amd64"
  talos_extensions = ["qemu-guest-agent"]

  cluster_name     = "home-ops"
  cluster_endpoint = "https://${local.cluster_name}-k8s.mgmt.h.mirceanton.com:6443"

  pve_iso_datastore = "ceph-fs"
  pve_nodes = [ "pve01", "pve02", "pve03" ]
}