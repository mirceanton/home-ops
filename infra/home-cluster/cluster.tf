## ================================================================================================
## Generate a custom installer image for each node using the Talos Image Factory
## ================================================================================================
data "http" "talos_image_hash_controlplane" {
  for_each = var.node_data.controlplanes
  url      = "https://factory.talos.dev/schematics"
  method   = "POST"
  insecure = true

  request_body = yamlencode({
    "customization": {
      "systemExtensions": {
        "officialExtensions": each.value.system_extensions
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
    "customization": {
      "systemExtensions": {
        "officialExtensions": each.value.system_extensions
      }
    }
  })
}


## ================================================================================================
## talosctl gen secrets
## ================================================================================================
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}


## ================================================================================================
## talosctl gen config
## ================================================================================================
data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_vip}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  # Role-specific config patches
  config_patches = [
    file("${path.module}/patches/allow-controlplane-workloads.yaml"),
    file("${path.module}/patches/cni.yaml"),
    file("${path.module}/patches/keycloak-auth.yaml"),
    file("${path.module}/patches/kubelet-certificate-rotation.yaml")
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cluster_vip}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  # Role-specific config patches
  config_patches = [
    file("${path.module}/patches/cni.yaml"),
    file("${path.module}/patches/kubelet-certificate-rotation.yaml")
  ]
}


## ================================================================================================
## talosctl apply-config --config-patch ...
## ================================================================================================
resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = var.node_data.controlplanes
  node                        = each.key

  # Node-specific config patches
  config_patches = [
    templatefile("${path.module}/templates/controlplane-vip.yaml", {
      interface   = each.value.interface,
      cluster_vip = var.cluster_vip
    }),
    templatefile("${path.module}/templates/dhcp.yaml", {
      hostname  = format("%s-cp-%s", var.cluster_name, index(keys(var.node_data.controlplanes), each.key)),
      interface = each.value.interface
    }),
    templatefile("${path.module}/templates/install-disk.yaml", {
      install_disk = each.value.install_disk
    }),
    templatefile("${path.module}/templates/installer-image.yaml", {
      image_hash    = jsondecode(data.http.talos_image_hash_controlplane[each.key].response_body)["id"]
      talos_version = var.talos_version
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.node_data.workers
  node                        = each.key

  # Node-specific config patches
  config_patches = [
    templatefile("${path.module}/templates/dhcp.yaml", {
      hostname  = format("%s-wkr-%s", var.cluster_name, index(keys(var.node_data.workers), each.key)),
      interface = each.value.interface
    }),
    templatefile("${path.module}/templates/install-disk.yaml", {
      install_disk = each.value.install_disk
    }),
    templatefile("${path.module}/templates/installer-image.yaml", {
      image_hash    = jsondecode(data.http.talos_image_hash_worker[each.key].response_body)["id"]
      talos_version = var.talos_version
    }),
  ]
}


## ================================================================================================
## talosctl bootstrap
## ================================================================================================
resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : k][0]
}


## ================================================================================================
## talosctl upgrade (to make sure system extensions are always applied I guess)
## ================================================================================================
resource "null_resource" "talosctl_upgrade_controlplane" {
  for_each                    = var.node_data.controlplanes

  triggers = {
    talos_version = var.talos_version,          # trigger the upgrade when changing the Talos OS version
    extensions = each.value.system_extensions,  # trigger the upgrade when changing the system extensions
  }

  # run the upgrade command after the cluster is up and running
  depends_on = [ talos_cluster_kubeconfig.this ]

  provisioner "local-exec" {
    environment = {
      INSTALLER_IMAGE = jsondecode(data.http.talos_image_hash_controlplane[each.key].response_body)["id"]
      EXTRA_FLAGS = length(var.node_data.controlplanes) < 3 ? "--preserve" : ""
    }
    command = <<EOT
        talosctl upgrade \
            --talosconfig ${local_file.talosconfig.filename} \
            --nodes ${each.key} \
            --image factory.talos.dev/installer/$INSTALLER_IMAGE:${var.talos_version}
            $EXTRA_FLAGS
    EOT
  }
}

resource "null_resource" "talosctl_upgrade_workers" {
  for_each                    = var.node_data.workers

  triggers = {
    talos_version = var.talos_version,          # trigger the upgrade when changing the Talos OS version
    extensions = each.value.system_extensions,  # trigger the upgrade when changing the system extensions
  }

  # upgrade workers after the controlplanes are upgraded
  depends_on = [ null_resource.talosctl_upgrade_controlplane ]

  provisioner "local-exec" {
    environment = {
      INSTALLER_IMAGE = jsondecode(data.http.talos_image_hash_controlplane[each.key].response_body)["id"]
    }

    command = <<EOT
        talosctl upgrade \
            --talosconfig ${local_file.talosconfig.filename} \
            --nodes ${each.key} \
            --image factory.talos.dev/installer/$INSTALLER_IMAGE:${var.talos_version}
    EOT
  }
}
