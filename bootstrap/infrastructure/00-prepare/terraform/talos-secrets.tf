resource "talos_machine_secrets" "cluster" {
  talos_version = var.talos_version
}

# =================================================================================================
# Outputs
# =================================================================================================
output "talos_machine_secrets" {
  description = "Talos machine secrets for the cluster"
  value       = talos_machine_secrets.cluster.machine_secrets
  sensitive   = true
}
output "talos_client_configuration" {
  description = "Talos client configuration for the cluster"
  value       = talos_machine_secrets.cluster.client_configuration
  sensitive   = true
}