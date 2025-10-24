resource "proxmox_virtual_environment_pool" "cluster" {
  comment = "Resource pool for ${var.cluster_name} Kubernetes cluster"
  pool_id = var.cluster_name
}


# =================================================================================================
# Outputs
# =================================================================================================
output "resource_pool_id" {
  description = "Proxmox resource pool ID"
  value       = proxmox_virtual_environment_pool.cluster.pool_id
}
