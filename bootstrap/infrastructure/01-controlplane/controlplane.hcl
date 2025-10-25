locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))

  base_vm_id = 1100

  # VM Specs
  cpu_type       = "host"
  cpu_cores      = 4
  memory_mb      = 8192
  disk_size_gb   = 40
  disk_datastore = "local-lvm"
  network_bridge = "vmbr0"

  talos_config_patches = [
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "eth0"
              vip = {
                ip = tostring(regex("https://([0-9.]+):[0-9]+", local.root.locals.cluster_endpoint)[0])
              }
            }
          ]
        }
      }
    }),
  ]
}