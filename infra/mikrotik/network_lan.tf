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


