resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = var.proxmox_node
  url          = data.talos_image_factory_urls.this.urls.iso
  file_name    = "talos-${var.talos_version}-${var.talos_platform}-${var.architecture}.iso"
}


# =================================================================================================
# Outputs
# =================================================================================================
output "talos_iso_id" {
  description = "Proxmox file ID for the Talos ISO"
  value       = proxmox_virtual_environment_download_file.talos_iso.id
}
