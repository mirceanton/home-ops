variable "pve_endpoint" {
  type = string
  description = "The endpoint for the Proxmox Virtual Environment API"
}
variable "pve_username" {
  type = string
  default = "root@pam"
  description = "The username and realm for the Proxmox Virtual Environment API."
}
variable "pve_password" {
  type = string
  description = "The password for the Proxmox Virtual Environment API."
}
variable "pve_insecure" {
  type = bool
  default = true
  description = "Whether or not to skip the TLS verification step."
}

variable "talos_version" {
  type = string
}

variable "pve_resource_pool" {
  type = string
  default = "Talos"
  
}

variable "pve_iso_datastore" {
  type = string
}
variable "pve_node_name" {
  type = string
}


variable "talos_node_count" {
  type = number
  default = 3
}

variable "talos_node_cpus" {
  type = number
  default = 4
}

variable "talos_node_memory" {
  type = number
  default = 8192
}

variable "talos_node_bridge" {
  type = string
  default = "vmbr0"
}

variable "talos_node_disk_datastore" {
  type = string
  default = "local-zfs"
}
variable "talos_node_disk_file_format" {
  type = string
}
variable "talos_node_disk_interface" {
  type = string
}
variable "talos_node_disk_size" {
  type = number
}