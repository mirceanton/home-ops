# =================================================================================================
# Provider Configuration
# =================================================================================================
terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.72.0"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "0.12.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}


# =================================================================================================
# Mikrotik Devices
# =================================================================================================
provider "routeros" {
  alias = "rb5009"

  hosturl  = "https://192.168.88.1"
  username = var.mikrotik_router_username
  password = var.mikrotik_router_password
  insecure = true
}
provider "routeros" {
  alias = "crs326"

  hosturl  = "https://192.168.88.2"
  username = var.mikrotik_router_username
  password = var.mikrotik_router_password
  insecure = true
}
provider "routeros" {
  alias = "crs317"

  hosturl  = "https://192.168.88.3"
  username = var.mikrotik_router_username
  password = var.mikrotik_router_password
  insecure = true
}


# =================================================================================================
# Bitwarden
# =================================================================================================
provider "bitwarden" {
  server          = var.bitwarden_server_url
  email           = var.bitwarden_email
  client_id       = var.bitwarden_client_id
  client_secret   = var.bitwarden_client_secret
  master_password = var.bitwarden_master_password
}
