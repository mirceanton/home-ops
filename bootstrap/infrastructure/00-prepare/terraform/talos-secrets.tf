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
