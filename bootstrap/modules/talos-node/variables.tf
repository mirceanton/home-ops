variable "talos_version" {
  description = "Talos Linux version (e.g., 'v1.7.0')"
  type        = string
}
variable "talos_installer_image" {
  description = "Talos installer image URL"
  type        = string
}
variable "talos_config_patches" {
  description = "List of Talos configuration patches to apply"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}
variable "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  type        = string
}

variable "talos_machine_secrets" {
  description = "Talos machine secrets object"
  type = any
  sensitive = true
}
variable "talos_client_configuration" {
  description = "Talos client configuration object"
  type = any
  sensitive = true
}
variable "talos_iso_id" {
  description = "Proxmox file ID for the Talos ISO"
  type        = string
}

variable "talos_bootstrap" {
  description = "Whether to bootstrap the cluster on this node (only for first controlplane)"
  type        = bool
  default     = false
}

variable "node_name" {
  description = "Name of the node (e.g., 'controlplane-1', 'worker-1')"
  type        = string
}
variable "node_role" {
  description = "Role of the node: 'controlplane' or 'worker'"
  type        = string
  validation {
    condition     = contains(["controlplane", "worker"], var.node_role)
    error_message = "node_role must be either 'controlplane' or 'worker'"
  }
}


variable "proxmox_node" {
  description = "Proxmox node to create VM on"
  type        = string
}
variable "proxmox_resource_pool_id" {
  description = "Proxmox resource pool ID"
  type        = string
}


variable "vm_id" {
  description = "VM ID in Proxmox"
  type        = number
}
variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
}
variable "cpu_type" {
  description = "CPU type for the VM"
  type        = string
  default     = "x86-64-v2-AES"
}
variable "cpu_arch" {
  description = "CPU architecture: 'amd64' or 'arm64'"
  type        = string
  default     = "amd64"
  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "cpu_arch must be either 'amd64' or 'arm64'"
  }
}
variable "memory" {
  description = "Memory in MB"
  type        = number
}
variable "disk_size" {
  description = "Disk size in GB"
  type        = number
}
variable "disk_datastore" {
  description = "Datastore for VM disk"
  type        = string
}
variable "network_bridge" {
  description = "Network bridge for the VM"
  type        = string
  default     = "vmbr0"
}


variable "ip_address" {
  description = "Static IP address for the node (e.g., '192.168.1.10/24')"
  type        = string
}
variable "gateway" {
  description = "Network gateway"
  type        = string
}

