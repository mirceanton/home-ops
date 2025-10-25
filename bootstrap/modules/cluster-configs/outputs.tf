output "talosconfig_path" {
  description = "Path where the talosconfig was saved (if applicable)"
  value       = var.talosconfig_save_path != "" ? var.talosconfig_save_path : null
}

output "kubeconfig_path" {
  description = "Path where the kubeconfig was saved (if applicable)"
  value       = var.kubeconfig_save_path != "" ? var.kubeconfig_save_path : null
}
