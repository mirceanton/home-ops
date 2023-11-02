terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.20.0"
    }
  }
}

provider "routeros" {
  hosturl  = var.mikrotik_router_url
  username = var.mikrotik_router_username
  password = var.mikrotik_router_password
  insecure = var.mikrotik_router_insecure_skip_tls_verify
}

resource "routeros_system_identity" "identity" {
  name = "homebase"
}
