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
resource "routeros_interface_bridge_port" "management_odroid_c4" {
  bridge    = routeros_interface_bridge.management.name
  interface = routeros_interface_ethernet.odroid_c4.name
  comment   = routeros_interface_ethernet.odroid_c4.comment
  pvid      = "1"
}


## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_pool" "management" {
  name    = "management-dhcp-pool"
  comment = "Management DHCP Pool"
  ranges  = ["10.0.0.100-10.0.0.199"]
}
resource "routeros_ip_dhcp_server_network" "management" {
  comment    = "Management DHCP Network"
  domain     = "management.${local.internal_domain}"
  address    = "10.0.0.0/24"
  gateway    = "10.0.0.1"
  dns_server = ["10.0.0.1"]
}
resource "routeros_ip_dhcp_server" "management" {
  name               = "management-dhcp"
  comment            = "Management DHCP Server"
  address_pool       = routeros_ip_pool.management.name
  interface          = routeros_interface_bridge.management.name
  client_mac_limit   = 1
  conflict_detection = false
}
