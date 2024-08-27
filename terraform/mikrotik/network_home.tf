## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "home" {
  name           = "brHOME"
  vlan_filtering = false
}
resource "routeros_ip_address" "home" {
  address   = "192.168.69.1/24"
  interface = routeros_interface_bridge.home.name
  network   = "192.168.69.0"
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "home_switch" {
  bridge    = routeros_interface_bridge.home.name
  interface = routeros_interface_ethernet.home.name
  comment   = routeros_interface_ethernet.home.comment
  pvid      = "1"
}


## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_pool" "home" {
  name    = "home-dhcp-pool"
  comment = "Home DHCP Pool"
  ranges  = ["192.168.69.100-192.168.69.199"]
}
resource "routeros_ip_dhcp_server_network" "home" {
  comment    = "Home DHCP Network"
  domain     = "home.${local.internal_domain}"
  address    = "192.168.69.0/24"
  gateway    = "192.168.69.1"
  dns_server = ["192.168.69.1"]
}
resource "routeros_ip_dhcp_server" "home" {
  name               = "home-dhcp"
  comment            = "Home DHCP Server"
  address_pool       = routeros_ip_pool.home.name
  interface          = routeros_interface_bridge.home.name
  client_mac_limit   = 1
  conflict_detection = false
}


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "home_switch" {
  address     = "192.168.69.2"
  mac_address = "00:EE:AB:28:1C:81"
  server      = routeros_ip_dhcp_server.home.name
  comment     = "Cisco SG350-10"
}
resource "routeros_ip_dhcp_server_lease" "home_NUC" {
  address     = "192.168.69.69"
  mac_address = "08:BF:B8:69:9D:C8"
  server      = routeros_ip_dhcp_server.home.name
  comment     = "Mircea Desktop PC"
}
resource "routeros_ip_dhcp_server_lease" "home_home_assistant" {
  address     = "192.168.69.252"
  mac_address = "00:1E:06:42:C7:73"
  server      = routeros_ip_dhcp_server.home.name
  comment     = "HomeAssistant"
}
resource "routeros_ip_dhcp_server_lease" "home_truenas" {
  address     = "192.168.69.254"
  mac_address = "E0:D5:5E:24:A1:EC"
  server      = routeros_ip_dhcp_server.home.name
  comment     = "TrueNAS"
}
resource "routeros_ip_dhcp_server_lease" "home_gaming_pc" {
  address     = "192.168.69.99"
  mac_address = "74:56:3C:B7:9B:D8"
  server      = routeros_ip_dhcp_server.home.name
  comment     = "Gaming PC"
}
# TODO static lease MikroTik AP
