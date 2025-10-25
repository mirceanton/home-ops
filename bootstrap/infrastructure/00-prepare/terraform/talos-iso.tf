# Fetch the Talos extension versions for the specified Talos version
data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_version
  filters = { names = [ "qemu-guest-agent" ] }
}


# Create a Talos image factory schematic with the specified extensions
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

# Fetch the Talos image URLs based on the schematic
data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = var.talos_platform
  architecture  = var.architecture
}


# =================================================================================================
# Outputs
# =================================================================================================
output "schematic_id" {
  description = "Talos image factory schematic ID"
  value = talos_image_factory_schematic.this.id
}
output "installer_url" {
  description = "Talos installer URL"
  value = data.talos_image_factory_urls.this.urls.installer
}
output "iso_url" {
  description = "Talos ISO URL"
  value = data.talos_image_factory_urls.this.urls.iso
}
