locals {
  disable_service = { "api" = 8728, "ftp" = 21, "telnet" = 23, "www" = 80, "ssh" = 22 }
  enable_service  = { "winbox" = 8291, "api-ssl" = 8729, "www-ssl" = 443 }
}

resource "routeros_ip_service" "disabled" {
  for_each = local.disable_service
  numbers  = each.key
  port     = each.value
  disabled = true
}


resource "routeros_ip_service" "enabled" {
  for_each = local.enable_service
  numbers  = each.key
  port     = each.value
  disabled = false
}


import {
  to = routeros_system_certificate.local-root-ca-cert
  id = "*1"
}
resource "routeros_system_certificate" "local-root-ca-cert" {
  name        = "local-root-cert"
  common_name = "local-cert"
  key_size    = "prime256v1"
  key_usage   = ["key-cert-sign", "crl-sign"]
  trusted     = true
  sign {}
}


import {
  to = routeros_system_certificate.webfig
  id = "*2"
}
resource "routeros_system_certificate" "webfig" {
  name        = "webfig"
  common_name = "192.168.69.1"

  country      = "RO"
  locality     = "BUC"
  organization = "MIRCEANTON"
  unit         = "HOME"
  days_valid   = 3650

  key_usage = ["key-cert-sign", "crl-sign", "digital-signature", "key-agreement", "tls-server"]
  key_size  = "prime256v1"

  trusted = true
  sign {
    ca = routeros_system_certificate.local-root-ca-cert.name
  }
}
