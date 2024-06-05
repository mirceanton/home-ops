locals {
  tls_service     = {"api-ssl" = 8729, "www-ssl" = 443}
  disable_service = {"api" = 8728, "ftp" = 21, "telnet" = 23, "www" = 80, "ssh" = 22}
  enable_service  = { "winbox" = 8291}
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
  address = "${routeros_ip_address.management.network}/24,${routeros_ip_dhcp_server_lease.lan_desktop.address}/32"
  disabled = false
}


resource "routeros_system_certificate" "webfig" {
  name        = "webfig"
  common_name = routeros_ip_dns_record.mgmt_self.name
  subject_alt_name = ""#"IP:${routeros_ip_dns_record.mgmt_self.name},DNS:${routeros_ip_dns_record.lan_self.name},IP:${routeros_ip_dns_record.lan_self.address}"

  country = "RO"
  locality = "BUC"
  organization = "MIRCEANTON"
  unit = "HOME"
  days_valid  = 3650

  key_usage   = ["key-cert-sign", "crl-sign", "digital-signature", "key-agreement", "tls-server"]
  key_size    = "prime256v1"

  trusted = true

  lifecycle {
    ignore_changes = [
      sign,
    ]
  }
}

resource "routeros_ip_service" "api-ssl" {
  for_each    = local.tls_service
  numbers     = each.key
  port        = each.value

  address = "${routeros_ip_address.management.network}/24,${routeros_ip_dhcp_server_lease.lan_desktop.address}/32"
  tls_version = "only-1.2"
  disabled    = false
  certificate = routeros_system_certificate.webfig.name
}