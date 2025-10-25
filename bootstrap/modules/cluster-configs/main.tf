resource "local_file" "talosconfig" {
  content  = var.talosconfig_content
  filename = var.talosconfig_save_path
}

resource "local_file" "kubeconfig" {
  content  = var.kubeconfig_content
  filename = var.kubeconfig_save_path
}
