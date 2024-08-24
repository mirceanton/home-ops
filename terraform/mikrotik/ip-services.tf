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

