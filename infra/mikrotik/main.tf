locals {
  base_domain = "mirceanton.com"
}

resource "routeros_system_identity" "identity" {
  name = "MikroTik-RB5009"
}

resource "routeros_dns" "dns-server" {
  allow_remote_requests = true
  servers               = "1.1.1.1,8.8.8.8"
}
