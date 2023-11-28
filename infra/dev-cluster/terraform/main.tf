resource "proxmox_virtual_environment_file" "talos_image" {
  content_type = "iso"
  datastore_id = var.pve_iso_datastore
  node_name    = var.pve_node_name

  source_file {
    path      = "https://github.com/siderolabs/talos/releases/download/${var.talos_version}/metal-amd64.iso"
    file_name = "talos-${var.talos_version}-amd64.iso"
  }
}

resource "proxmox_virtual_environment_pool" "talos_pool" {
  comment = "Talos Cluster"
  pool_id = var.pve_resource_pool
}

resource "proxmox_virtual_environment_vm" "talos_vm" {
  count = var.talos_node_count

  bios = "seabios"
  cpu {
    architecture = "x86_64"
    cores = var.talos_node_cpus
    numa = false
    sockets = 1
    type  = "host"
  }
  description = "Talos Node ${count.index + 1}"
  disk {
    datastore_id = var.talos_node_disk_datastore
    file_id      = proxmox_virtual_environment_file.talos_image.id
    file_format  = var.talos_node_disk_file_format
    interface    = var.talos_node_disk_interface
    size         = var.talos_node_disk_size
    ssd = true
    iothread = true
  }
  machine = "q35"
  memory {
    dedicated = var.talos_node_memory
  }
  name        = "talos-node-${count.index + 1}"
  network_device {
    bridge      = var.talos_node_bridge
    model = "virtio"
  }
  node_name = var.pve_node_name
  on_boot = false
  operating_system {
    type = "l26"
  }
  pool_id   = proxmox_virtual_environment_pool.talos_pool.id
  scsi_hardware = "virtio-scsi-single"
}
