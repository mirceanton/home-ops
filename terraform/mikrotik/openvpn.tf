# =================================================================================================
# Certificate Setup
# =================================================================================================
resource "routeros_system_certificate" "ovpn_ca" {
  name        = "OpenVPN-Root-CA"
  common_name = "OpenVPN Root CA"
  key_size    = "prime256v1"
  key_usage   = ["key-cert-sign", "crl-sign"]
  trusted     = true
  sign {}
}

resource "routeros_system_certificate" "ovpn_server_crt" {
  name        = "OpenVPN-Server-Certificate"
  common_name = "Mikrotik OpenVPN"
  key_size    = "prime256v1"
  key_usage   = ["digital-signature", "key-encipherment", "tls-server"]
  sign {
    ca = routeros_system_certificate.ovpn_ca.name
  }
}

resource "routeros_system_certificate" "ovpn_client_crt" {
  name        = "OpenVPN-Client-Certificate"
  common_name = "Mikrotik OpenVPN Client"
  key_size    = "prime256v1"
  key_usage   = ["tls-client"]
  sign {
    ca = routeros_system_certificate.ovpn_ca.name
  }

  country      = "RO"
  state        = "B"
  locality     = "BUC"
  organization = "MIRCEANTON"
  unit         = "HOME"
  days_valid   = 3650 # 10 years
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
  name           = "ovpn"
  local_address  = "172.16.69.1"
  remote_address = routeros_ip_pool.ovpn-pool.name
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
# Firewall Rules
# =================================================================================================
resource "routeros_ip_firewall_nat" "ovpn_nat" {
  chain       = "srcnat"
  src_address = "172.16.69.0/24"
  action      = "masquerade"
}
resource "routeros_ip_firewall_filter" "ovpn_pass" {
  comment  = "Allow OpenVPN traffic"
  chain    = "input"
  dst_port = "1194" # OpenVPN port
  protocol = "tcp"
  action   = "accept"

  log        = true
  log_prefix = "ovpn_"
}
