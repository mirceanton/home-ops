
resource "routeros_ip_firewall_filter" "drop_invalid_input" {
  chain           = "input"
  connection_state = "invalid"
  action          = "drop"
  comment         = "Drop invalid input packets"
}

resource "routeros_ip_firewall_filter" "drop_invalid_forward" {
  chain           = "forward"
  connection_state = "invalid"
  action          = "drop"
  comment         = "Drop invalid forward packets"
}

resource "routeros_ip_firewall_filter" "accept_established_related_input" {
  chain            = "input"
  connection_state = "established,related"
  action           = "accept"
  comment          = "Accept established and related input connections"
}

resource "routeros_ip_firewall_filter" "accept_established_related_forward" {
  chain            = "forward"
  connection_state = "established,related"
  action           = "accept"
  comment          = "Accept established and related forward connections"
}

resource "routeros_ip_firewall_filter" "accept_icmp" {
  chain   = "input"
  protocol = "icmp"
  action  = "accept"
  comment = "Allow ICMP (Ping)"
}

resource "routeros_ip_firewall_filter" "accept_dns_udp" {
  chain  = "input"
  protocol = "udp"
  port    = "53"
  action  = "accept"
  comment = "Allow DNS UDP queries"
}

resource "routeros_ip_firewall_filter" "accept_dns_tcp" {
  chain  = "input"
  protocol = "tcp"
  port    = "53"
  action  = "accept"
  comment = "Allow DNS TCP queries"
}

resource "routeros_ip_firewall_filter" "accept_dhcp" {
  chain  = "input"
  protocol = "udp"
  port    = "67,68"
  action  = "accept"
  comment = "Allow DHCP"
}

resource "routeros_ip_firewall_filter" "allow_lan_to_wan" {
  chain       = "forward"
  src_address = routeros_ip_dhcp_server_network.lan.address
  out_interface = routeros_interface_bridge.wan.name
  action      = "accept"
  comment     = "Allow LAN to WAN traffic"
}

resource "routeros_ip_firewall_filter" "allow_management_to_wan" {
  chain       = "forward"
  src_address = routeros_ip_dhcp_server_network.management.address
  out_interface = routeros_interface_bridge.wan.name
  action      = "accept"
  comment     = "Allow Management to WAN traffic"
}

resource "routeros_ip_firewall_filter" "block_lan_to_management" {
  chain       = "forward"
  src_address = routeros_ip_dhcp_server_network.lan.address
  dst_address = routeros_ip_dhcp_server_network.management.address
  action      = "drop"
  comment     = "Block LAN to Management traffic"
}

resource "routeros_ip_firewall_filter" "allow_management_to_lan" {
  chain       = "forward"
  src_address = routeros_ip_dhcp_server_network.management.address
  dst_address = routeros_ip_dhcp_server_network.lan.address
  action      = "accept"
  comment     = "Allow Management to LAN traffic"
}

# resource "routeros_ip_firewall_filter" "drop_other_forward" {
#   chain   = "forward"
#   action  = "drop"
#   comment = "Drop all other forward traffic"
# }
