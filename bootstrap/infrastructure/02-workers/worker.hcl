locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))

  base_vm_id = 1200

  # VM Specs
  cpu_type       = "host"
  cpu_cores      = 8
  memory_mb      = 16384
  disk_size_gb   = 100
  disk_datastore = "local-lvm"
  network_bridge = "vmbr0"

  talos_config_patches = []
}