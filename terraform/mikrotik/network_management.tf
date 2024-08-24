## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "management" {
  name           = "brMANAGEMENT"
  vlan_filtering = true
}
resource "routeros_ip_address" "management" {
  address   = "10.0.0.1/24"
  interface = routeros_interface_bridge.management.name
  network   = "10.0.0.0"
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "management_switch" {
  bridge    = routeros_interface_bridge.management.name
  interface = routeros_interface_ethernet.management.name
  comment   = routeros_interface_ethernet.management.comment
  pvid      = "1"
}
