## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "wan" {
  name           = "brWAN"
  vlan_filtering = false
}


## ================================================================================================
## Bridge Ports
## ================================================================================================

resource "routeros_interface_bridge_port" "wan_uplink" {
  bridge    = routeros_interface_bridge.wan.name
  interface = routeros_interface_ethernet.wan.name
  comment   = routeros_interface_ethernet.wan.comment
  pvid      = "1"
}

## ================================================================================================
## DHCP Client Config
## ================================================================================================
resource "routeros_ip_dhcp_client" "wan" {
  interface = routeros_interface_bridge.wan.name
  comment   = "WAN DHCP Client"
}
