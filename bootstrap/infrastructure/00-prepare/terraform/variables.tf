variable "talos_version" {
  description = "Talos Linux version"
  type        = string
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node to download ISO to"
  type        = string
}

variable "iso_datastore" {
  description = "Datastore to store the Talos ISO"
  type        = string
}

variable "talos_extensions" {
  description = "Talos extensions to enable"
  type        = list(string)
  default     = []
}

variable "talos_platform" {
  description = "Talos platform. (aws, gcp, nocloud, openstack, metal etc.)"
  type        = string
  default     = "nocloud"
}

variable "architecture" {
  description = "Talos architecture (e.g., amd64, arm64)"
  type        = string
  default     = "amd64"
  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "architecture must be either 'amd64' or 'arm64'"
  }
}
