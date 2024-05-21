## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "wan" {
  name           = "brWAN"
  vlan_filtering = false
}

resource "routeros_interface_bridge_port" "wan" {
  bridge    = routeros_interface_bridge.wan.name
  interface = routeros_interface_ethernet.wan.name
  pvid      = "1"
}


## ================================================================================================
## DHCP Client Config
## ================================================================================================
resource "routeros_ip_dhcp_client" "wan" {
  interface = routeros_interface_ethernet.wan.name
  comment   = "WAN DHCP Client"
}


## ================================================================================================
## NAT Configuration
## ================================================================================================
resource "routeros_ip_firewall_nat" "wan_default_nat" {
  action        = "masquerade"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
}