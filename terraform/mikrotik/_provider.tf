terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.72.0"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "0.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "routeros" {
  hosturl  = var.mikrotik_router_url
  username = var.mikrotik_router_username
  password = var.mikrotik_router_password
  insecure = var.mikrotik_router_insecure_skip_tls_verify
}

provider "bitwarden" {
  server          = var.bitwarden_server_url
  email           = var.bitwarden_email
  client_id       = var.bitwarden_client_id
  client_secret   = var.bitwarden_client_secret
  master_password = var.bitwarden_master_password
}
