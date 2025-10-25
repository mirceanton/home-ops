include "root" { path = find_in_parent_folders("root.hcl") }
include "worker" { path = find_in_parent_folders("worker.hcl") }

dependency "prepare" { config_path = find_in_parent_folders("00-prepare") }
dependencies {
  paths = [
    find_in_parent_folders("01-controlplane/controlplane-01"),
    find_in_parent_folders("01-controlplane/controlplane-02"),
    find_in_parent_folders("01-controlplane/controlplane-03"),
  ]
}

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  wrk   = read_terragrunt_config(find_in_parent_folders("worker.hcl"))
}

terraform { source = find_in_parent_folders("modules/talos-node") }
inputs = {
  node_name = "wrk-01"
  node_role = "worker"

  # Talos Info
  talos_version         = local.root.locals.talos_version
  talos_installer_image = dependency.prepare.outputs.installer_url
  talos_machine_secrets = dependency.prepare.outputs.talos_machine_secrets
  talos_client_configuration = dependency.prepare.outputs.talos_client_configuration
  talos_config_patches  = local.wrk.locals.talos_config_patches

  # Cluster Info
  cluster_name     = local.root.locals.cluster_name
  cluster_endpoint = local.root.locals.cluster_endpoint

  # Proxmox Info
  proxmox_node             = local.root.locals.pve_nodes[0]
  proxmox_resource_pool_id = dependency.prepare.outputs.resource_pool_id

  # VM Specs
  vm_id          = local.wrk.locals.base_vm_id + 0
  cpu_cores      = local.wrk.locals.cpu_cores
  cpu_type       = local.wrk.locals.cpu_type
  cpu_arch       = local.root.locals.architecture
  memory         = local.wrk.locals.memory_mb
  disk_size      = local.wrk.locals.disk_size_gb
  disk_datastore = local.wrk.locals.disk_datastore
  talos_iso_id   = dependency.prepare.outputs.talos_iso_id
  network_bridge = local.wrk.locals.network_bridge

  # Network Info
  ip_address = "${local.root.locals.worker_ips[0]}/24"
  gateway    = local.root.locals.gateway
}