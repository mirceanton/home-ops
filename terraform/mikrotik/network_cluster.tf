## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "cluster" {
  name           = "brCLUSTER"
  vlan_filtering = true
}
resource "routeros_ip_address" "cluster" {
  address   = "10.0.10.1/24"
  interface = routeros_interface_bridge.cluster.name
  network   = "10.0.10.0"
}
