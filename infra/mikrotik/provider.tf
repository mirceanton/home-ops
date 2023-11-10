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
  name = "MikroTik-RB5009"
}

resource "routeros_dns" "dns-server" {
  allow_remote_requests = true
  servers               = "1.1.1.1,8.8.8.8"
}
