# =================================================================================================
# Certificate Setup
# =================================================================================================
resource "routeros_system_certificate" "ovpn_ca" {
  name        = "OpenVPN-Root-CA"
  common_name = "OpenVPN Root CA"
  key_size    = "prime256v1"
  key_usage   = ["key-cert-sign", "crl-sign"]
  trusted     = true
  days_valid  = 3650
  sign {
    ca_crl_host = "vpn.mirceanton.com"
  }
}

resource "routeros_system_certificate" "ovpn_server_crt" {
  name        = "OpenVPN-Server-Certificate"
  common_name = "Mikrotik OpenVPN"
  key_size    = "prime256v1"
  key_usage   = ["digital-signature", "key-encipherment", "tls-server"]

  country      = "RO"
  locality     = "BUC"
  organization = "MIRCEANTON"
  unit         = "VPN"
  days_valid   = 3650

  sign {
    ca = routeros_system_certificate.ovpn_ca.name
  }
}


# =================================================================================================
# IP Pool
# =================================================================================================
resource "routeros_ip_pool" "ovpn-pool" {
  name    = "ovpn-pool"
  comment = "OpenVPN Pool"
  ranges  = ["172.16.69.2-172.16.69.254"]
}


# =================================================================================================
# PPP Profile
# =================================================================================================
resource "routeros_ppp_profile" "ovpn" {
  name            = "ovpn"
  local_address   = "172.16.69.1"
  remote_address  = routeros_ip_pool.ovpn-pool.name
  dns_server      = routeros_ip_dhcp_server_network.home.dns_server
  only_one        = "yes"
  use_upnp        = "yes"
  use_compression = "yes"
  use_encryption  = "yes"
  on_up           = <<-EOF
    :local webhookUrl "${var.discord_webhook_url}";
    :local address $"remote-address"
    :local Text "User `$user` has connected to the VPN as `$address`!";
    /tool fetch url=($webhookUrl) http-method=post http-data=("content=" . $Text) mode=https keep-result=no
  EOF
  on_down         = <<-EOF
    :local webhookUrl "${var.discord_webhook_url}";
    :local address $"remote-address"
    :local Text "User `$user` has disconnected from the VPN!";
    /tool fetch url=($webhookUrl) http-method=post http-data=("content=" . $Text) mode=https keep-result=no
  EOF
}


# =================================================================================================
# OpenVPN Server
# =================================================================================================
resource "routeros_ovpn_server" "server" {
  enabled                    = true
  port                       = 1194
  mode                       = "ip"
  auth                       = ["sha256", "sha512"]
  protocol                   = "tcp"
  netmask                    = 24
  max_mtu                    = 1500
  keepalive_timeout          = 60
  default_profile            = routeros_ppp_profile.ovpn.name
  certificate                = routeros_system_certificate.ovpn_server_crt.name
  require_client_certificate = true
  tls_version                = "only-1.2"
}


# =================================================================================================
# OpenVPN Users
# =================================================================================================
locals {
  vpn_users = [
    "mirceanton", "bomkii", "kookmuc", "gradcristi", "gradadi"
  ]
}

module "vpn_user" {
  source   = "./module/vpn_user"
  for_each = toset(local.vpn_users)

  username                    = each.key
  vpn_profile                 = routeros_ppp_profile.ovpn.name
  bitwarden_organization_id   = "82cb7c0d-45c3-494c-81cf-b1d701208c8d"
  openvpn_ca_certificate_name = routeros_system_certificate.ovpn_ca.name
}
