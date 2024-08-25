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


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "cluster_switch" {
  bridge    = routeros_interface_bridge.cluster.name
  interface = routeros_interface_ethernet.cluster.name
  comment   = routeros_interface_ethernet.cluster.comment
  pvid      = "1"
}


## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_pool" "cluster" {
  name    = "cluster-dhcp-pool"
  comment = "Cluster DHCP Pool"
  ranges  = ["10.0.10.190-10.0.10.199"]
}
resource "routeros_ip_dhcp_server_network" "cluster" {
  comment    = "Cluster DHCP Network"
  domain     = "cluster.${local.internal_domain}"
  address    = "10.0.10.0/24"
  gateway    = "10.0.10.1"
  dns_server = ["10.0.10.1"]
}
resource "routeros_ip_dhcp_server" "cluster" {
  name               = "cluster-dhcp"
  comment            = "Cluster DHCP Server"
  address_pool       = routeros_ip_pool.cluster.name
  interface          = routeros_interface_bridge.cluster.name
  client_mac_limit   = 1
  conflict_detection = false
}
