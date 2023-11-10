resource "routeros_interface_bridge" "wan_bridge" {
  name           = "brWAN"
  vlan_filtering = false
}

resource "routeros_ip_dhcp_client" "wan_dhcp" {
  interface = routeros_interface_bridge.wan_bridge.name
}

resource "routeros_interface_bridge_port" "wan_bridge_port" {
  bridge    = routeros_interface_bridge.wan_bridge.name
  interface = "ether8"
  pvid      = "1"
}

resource "routeros_ip_firewall_nat" "wan_default_nat" {
  action        = "masquerade"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan_bridge.name
}