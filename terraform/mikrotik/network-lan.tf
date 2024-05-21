## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "lan" {
  name           = "brLAN"
  vlan_filtering = true
}
resource "routeros_ip_address" "lan" {
  address   = "192.168.69.1/24"
  interface = routeros_interface_bridge.lan.name
  network   = "192.168.69.0"
}
