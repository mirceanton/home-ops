## ================================================================================================
## Generate a custom installer image for each node using the Talos Image Factory
## ================================================================================================
data "http" "talos_image_hash_controlplane" {
  for_each = var.node_data.controlplanes
  url      = "https://factory.talos.dev/schematics"
  method   = "POST"
  insecure = true

  request_body = yamlencode({
    "customization" : {
      "systemExtensions" : {
        "officialExtensions" : each.value.system_extensions
      }
    }
  })
}
data "http" "talos_image_hash_worker" {
  for_each = var.node_data.workers
  url      = "https://factory.talos.dev/schematics"
  method   = "POST"
  insecure = true

  request_body = yamlencode({
    "customization" : {
      "systemExtensions" : {
        "officialExtensions" : each.value.system_extensions
      }
    }
  })
}


## ================================================================================================
## talosctl upgrade (to make sure system extensions are always applied I guess)
## ================================================================================================
resource "null_resource" "talosctl_upgrade_controlplane" {
  for_each = var.node_data.controlplanes

  triggers = {
    # trigger the upgrade when changing the Talos OS version
    talos_version = var.talos_version,

    # trigger the upgrade when changing the system extensions
    extensions = join(",", each.value.system_extensions)
  }

  provisioner "local-exec" {
    environment = {
      INSTALLER_IMAGE = jsondecode(data.http.talos_image_hash_controlplane[each.key].response_body)["id"]
      EXTRA_FLAGS     = length(var.node_data.controlplanes) < 3 ? "--preserve" : ""
    }
    command = <<EOT
        talosctl upgrade \
            --talosconfig ${var.talosconfig_file_path} \
            --nodes ${each.key} \
            --image factory.talos.dev/installer/$INSTALLER_IMAGE:${var.talos_version} \
            $EXTRA_FLAGS
    EOT
  }
}

resource "null_resource" "talosctl_upgrade_workers" {
  for_each = var.node_data.workers

  triggers = {
    # trigger the upgrade when changing the Talos OS version
    talos_version = var.talos_version,

    # trigger the upgrade when changing the system extensions
    extensions = join(",", each.value.system_extensions)
  }

  # upgrade workers after the controlplanes are upgraded
  depends_on = [null_resource.talosctl_upgrade_controlplane]

  provisioner "local-exec" {
    environment = {
      INSTALLER_IMAGE = jsondecode(data.http.talos_image_hash_worker[each.key].response_body)["id"]
    }

    command = <<EOT
        talosctl upgrade \
            --talosconfig ${var.talosconfig_file_path} \
            --nodes ${each.key} \
            --image factory.talos.dev/installer/$INSTALLER_IMAGE:${var.talos_version}
    EOT
  }
}
