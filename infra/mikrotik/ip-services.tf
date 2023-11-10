locals {
  tls_service     = { "api-ssl" = 8729, "www-ssl" = 443 }
  disable_service = { "api" = 8728, "ftp" = 21, "telnet" = 23, "www" = 80, "ssh" = 22 }
  enable_service  = { "winbox" = 8291 }
}

resource "routeros_system_certificate" "webfig_cert" {
  name        = "webfig"
  common_name = split("/",routeros_ip_address.lan_address.address)[0]
  country = "RO"
  days_valid  = 3650
  key_size    = "prime256v1"
  key_usage   = ["key-cert-sign", "crl-sign", "digital-signature", "key-agreement", "tls-server"]
  sign {
  }
}

resource "routeros_ip_service" "tls" {
  for_each    = local.tls_service
  numbers     = each.key
  port        = each.value
  certificate = routeros_system_certificate.webfig_cert.name
  tls_version = "only-1.2"
  disabled    = false
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
