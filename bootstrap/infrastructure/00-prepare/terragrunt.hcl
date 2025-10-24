include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

terraform {
  source = "./terraform"
}

inputs = {
  talos_version    = local.root.locals.talos_version
  cluster_name     = local.root.locals.cluster_name
  cluster_endpoint = local.root.locals.cluster_endpoint

  proxmox_node  = local.root.locals.pve_nodes[0]
  iso_datastore = local.root.locals.pve_iso_datastore

  talos_extensions = local.root.locals.talos_extensions
  talos_platform   = local.root.locals.talos_platform
  architecture     = local.root.locals.architecture
}