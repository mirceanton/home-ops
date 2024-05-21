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


## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_dhcp_server" "lan" {
  address_pool     = routeros_ip_pool.lan.name
  interface        = routeros_interface_bridge.lan.name
  name             = "LAN-dhcp"
  client_mac_limit = 1
  conflict_detection = true
}
resource "routeros_ip_dhcp_server_network" "lan" {
  address    = "192.168.69.0/24"
  caps_manager = "192.168.69.1"
  comment = "LAN DHCP Server"
  dns_server = "192.168.69.1"
  domain     = "home.mirceanton.com"
  gateway    = "192.168.69.1"
}
resource "routeros_ip_pool" "lan" {
  name   = "lan-dhcp-pool"
  ranges = [
    "192.168.69.100-192.168.69.199"
  ]
}

resource "routeros_ip_dhcp_server_lease" "desktop" {
  address     = "192.168.69.69"
  mac_address = "74:56:3C:B7:9B:D8"
  server      = routeros_ip_dhcp_server.lan.name
  comment     = "Mircea Desktop PC"
}
resource "routeros_ip_dhcp_server_lease" "access_point" {
  address     = "192.168.69.2"
  mac_address = "D4:01:C3:01:26:EC"
  server      = routeros_ip_dhcp_server.lan.name
  comment     = "Mikrotik cAP AX"
}
resource "routeros_ip_dhcp_server_lease" "truenas" {
  address     = "192.168.69.254"
  mac_address = "E0:D5:5E:24:A1:EC"
  server      = routeros_ip_dhcp_server.lan.name
  comment     = "TrueNAS LAN"
}
resource "routeros_ip_dhcp_server_lease" "home_assistant" {
  address     = "192.168.69.252"
  mac_address = "00:1E:06:42:C7:73"
  server      = routeros_ip_dhcp_server.lan.name
  comment     = "HomeAssistant"
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "desktop" {
  bridge    = routeros_interface_bridge.lan.name
  interface = routeros_interface_ethernet.desktop.name
  comment   = routeros_interface_ethernet.desktop.comment
  pvid      = "1"
}
resource "routeros_interface_bridge_port" "access_point" {
  bridge    = routeros_interface_bridge.lan.name
  interface = routeros_interface_ethernet.access_point.name
  comment   = routeros_interface_ethernet.access_point.comment
  pvid      = "1"
}
resource "routeros_interface_bridge_port" "truenas" {
  bridge    = routeros_interface_bridge.lan.name
  interface = routeros_interface_ethernet.truenas.name
  comment   = routeros_interface_ethernet.truenas.comment
  pvid      = "1"
}
resource "routeros_interface_bridge_port" "home_assistant" {
  bridge    = routeros_interface_bridge.lan.name
  interface = routeros_interface_ethernet.home_assistant.name
  comment   = routeros_interface_ethernet.home_assistant.comment
  pvid      = "1"
}
