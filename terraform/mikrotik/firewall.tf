resource "routeros_ip_firewall_nat" "home" {
  comment       = "NAT Home Traffic"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
  action        = "masquerade"
  src_address   = "${routeros_ip_address.home.network}/24"
}

resource "routeros_ip_firewall_nat" "management" {
  comment       = "NAT Management Traffic"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
  action        = "masquerade"
  src_address   = "${routeros_ip_address.management.network}/24"
}





resource "routeros_ip_firewall_nat" "ovpn" {
  comment       = "NAT OpenVPN Traffic"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
  action        = "masquerade"
  src_address   = "172.16.69.0/24"
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

