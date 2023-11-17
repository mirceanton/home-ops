resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for k, v in var.node_data.controlplanes : k]
  nodes                = [for k, v in var.node_data.controlplanes : k]
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  for_each                    = var.node_data.controlplanes
  node                        = each.key
  config_patches = [
    file("${path.module}/patches/allow-controlplane-workloads.yaml"),
    file("${path.module}/patches/cni.yaml"),
    file("${path.module}/patches/keycloak-auth.yaml"),
    file("${path.module}/patches/kubelet-certificate-rotation.yaml"),

    templatefile("${path.module}/templates/controlplane-vip.yaml", {
      mac_address = each.value.mac_address
    }),
    templatefile("${path.module}/templates/dhcp.yaml", {
      hostname    = each.value.hostname == null ? format("%s-cp-%s", var.cluster_name, index(keys(var.node_data.controlplanes), each.key)) : each.value.hostname
      mac_address = each.value.mac_address
    }),
    templatefile("${path.module}/templates/install-disk.yaml", {
      install_disk = each.value.install_disk
    }),
    templatefile("${path.module}/templates/system-extensions.yaml", {
      system_extensions = each.value.system_extensions
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each                    = var.node_data.workers
  node                        = each.key
  config_patches = [
    file("${path.module}/patches/allow-controlplane-workloads.yaml"),
    file("${path.module}/patches/cni.yaml"),
    file("${path.module}/patches/kubelet-certificate-rotation.yaml"),


    templatefile("${path.module}/templates/dhcp.yaml", {
      hostname    = each.value.hostname == null ? format("%s-cp-%s", var.cluster_name, index(keys(var.node_data.controlplanes), each.key)) : each.value.hostname
      mac_address = each.value.mac_address
    }),
    templatefile("${path.module}/templates/install-disk.yaml", {
      install_disk = each.value.install_disk
    }),
    templatefile("${path.module}/templates/system-extensions.yaml", {
      system_extensions = each.value.system_extensions
    }),
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : k][0]
}

data "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : k][0]
}

resource "local_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "~/.talos/configs/${var.cluster_name}.yaml"
}
resource "local_file" "kubeconfig" {
  content  = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "~/.kube/configs/${var.cluster_name}.yaml"
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}
