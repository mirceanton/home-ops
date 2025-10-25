locals {
  vm_name = "${var.cluster_name}-${var.node_name}-talos-${replace(var.talos_version, ".", "-")}"
  node_ip = split("/", var.ip_address)[0]

  patches = [
    yamlencode({
      machine = {
        install = {
          image = var.talos_installer_image
        }
      }
    }),
    yamlencode({
      network = {
        hostname = local.vm_name,
        interfaces = {
          eth0 = {
            dhcp = false
            address = [var.ip_address]
            gateway = var.gateway
          }
        }
      }
    }),
  ]
}

# Generate Talos machine configuration
data "talos_machine_configuration" "this" {
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = var.node_role
  machine_secrets  = var.talos_machine_secrets
  talos_version    = var.talos_version
  config_patches   = var.talos_config_patches
}

# Create the VM
resource "proxmox_virtual_environment_vm" "talos_node" {
  node_name = var.proxmox_node

  name        = local.vm_name
  description = "Talos ${var.node_role} node ${var.node_name}"
  tags        = ["talos", "talos-${var.talos_version}", var.cluster_name, var.node_role]

  vm_id   = var.vm_id
  pool_id = var.proxmox_resource_pool_id

  cpu {
    cores        = var.cpu_cores
    type         = var.cpu_type
    architecture = var.cpu_arch == "amd64" ? "x86_64" : "aarch64"
    sockets      = 1
    numa         = true
  }

  memory {
    dedicated = var.memory
  }

  # Boot Disk
  scsi_hardware = "virtio-scsi-single"
  disk {
    datastore_id = var.disk_datastore
    size         = var.disk_size
    interface    = "scsi0"
    file_format  = "raw"
  }

  # Talos ISO
  cdrom {
    file_id   = var.talos_iso_id
    interface = "ide0"
  }

  network_device {
    bridge = var.network_bridge
  }

  operating_system { type = "l26" }

  # For the talos live environment
  initialization {
    dns { servers = [var.gateway] }
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
  }

  started = true
  lifecycle {
    ignore_changes = [started]
  }
}

# Apply Talos configuration to the node
resource "talos_machine_configuration_apply" "this" {
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  client_configuration        = var.talos_client_configuration
  node                        = local.node_ip

  depends_on = [proxmox_virtual_environment_vm.talos_node]
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.talos_node.id]
  }
}

# Bootstrap the cluster (only for first controlplane)
resource "talos_machine_bootstrap" "this" {
  count = var.talos_bootstrap ? 1 : 0

  client_configuration = var.talos_client_configuration
  node                 = local.node_ip

  depends_on = [talos_machine_configuration_apply.this]
}
