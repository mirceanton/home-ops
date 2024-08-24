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

