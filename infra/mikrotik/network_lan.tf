resource "routeros_interface_bridge" "lan_bridge" {
  name           = "brLAN"
  vlan_filtering = true
}

resource "routeros_ip_address" "lan_address" {
  address   = "192.168.69.1/24"
  interface = routeros_interface_bridge.lan_bridge.name
  network   = "192.168.69.0"
}

resource "routeros_interface_bridge_port" "lan_bridge_port" {
  bridge    = routeros_interface_bridge.lan_bridge.name
  interface = "ether1"
  pvid      = "1"
}

resource "routeros_ip_pool" "lan_dhcp_pool" {
  name   = "lan_dhcp_pool"
  ranges = [
    "192.168.69.10-192.168.69.199"
  ]
}
resource "routeros_ip_dhcp_server" "lan_dhcp" {
  address_pool = routeros_ip_pool.lan_dhcp_pool.name
  interface    = routeros_interface_bridge.lan_bridge.name
  name         = "lan_dhcp"
}