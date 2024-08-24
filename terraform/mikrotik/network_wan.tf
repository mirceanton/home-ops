## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
import {
  to = routeros_interface_bridge.wan
  id = "*B"
}
resource "routeros_interface_bridge" "wan" {
  name           = "brWAN"
  vlan_filtering = true
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
import {
  to = routeros_interface_bridge_port.wan_uplink
  id = "*0"
}
resource "routeros_interface_bridge_port" "wan_uplink" {
  bridge    = routeros_interface_bridge.wan.name
  interface = routeros_interface_ethernet.wan.name
  comment   = routeros_interface_ethernet.wan.comment
  pvid      = "1"
}

## ================================================================================================
## DHCP Client Config
## ================================================================================================
import {
  to = routeros_ip_dhcp_client.wan
  id = "*1"
}
resource "routeros_ip_dhcp_client" "wan" {
  interface = routeros_interface_bridge.wan.name
  comment   = "WAN DHCP Client"
}
