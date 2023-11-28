terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.38.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.pve_endpoint
  username = var.pve_username
  password = var.pve_password
  insecure = var.pve_insecure
}