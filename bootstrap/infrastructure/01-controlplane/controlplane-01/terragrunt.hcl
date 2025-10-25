include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "controlplane" {
  path = find_in_parent_folders("controlplane.hcl")
}

dependency "prepare" {
  config_path = find_in_parent_folders("00-prepare")
}

terraform {
  source = find_in_parent_folders("modules/talos-node")
}

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  cp   = read_terragrunt_config(find_in_parent_folders("controlplane.hcl"))
}

inputs = {
  node_name = "cp-01"
  node_role = "controlplane"

  # Talos Info
  talos_version         = local.root.locals.talos_version
  talos_installer_image = dependency.prepare.outputs.installer_url
  talos_machine_secrets = dependency.prepare.outputs.talos_machine_secrets
  talos_client_configuration = dependency.prepare.outputs.talos_client_configuration
  talos_bootstrap       = true # Bootstrap only on first controlplane
  talos_config_patches  = local.cp.locals.talos_config_patches

  # Cluster Info
  cluster_name     = local.root.locals.cluster_name
  cluster_endpoint = local.root.locals.cluster_endpoint

  # Proxmox Info
  proxmox_node             = local.root.locals.pve_nodes[0]
  proxmox_resource_pool_id = dependency.prepare.outputs.resource_pool_id

  # VM Specs
  vm_id          = local.cp.locals.base_vm_id + 0
  cpu_cores      = local.cp.locals.cpu_cores
  cpu_type       = local.cp.locals.cpu_type
  cpu_arch       = local.root.locals.architecture
  memory         = local.cp.locals.memory_mb
  disk_size      = local.cp.locals.disk_size_gb
  disk_datastore = local.cp.locals.disk_datastore
  talos_iso_id   = dependency.prepare.outputs.talos_iso_id
  network_bridge = local.cp.locals.network_bridge

  # Network Info
  ip_address = "${local.root.locals.controlplane_ips[0]}/24"
  gateway    = local.root.locals.gateway
}