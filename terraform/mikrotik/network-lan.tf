## ================================================================================================
## Interface Configuration
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
resource "routeros_interface_list_member" "lan_untrusted" {
  list      = routeros_interface_list.private_untrusted.name
  interface = routeros_interface_bridge.lan.name
}
resource "routeros_interface_list_member" "lan_internal" {
  list      = routeros_interface_list.internal.name
  interface = routeros_interface_bridge.lan.name
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "lan_desktop" {
  bridge    = routeros_interface_bridge.lan.name
  interface = routeros_interface_ethernet.desktop.name
  comment   = routeros_interface_ethernet.desktop.comment
  pvid      = "1"
}
resource "routeros_interface_bridge_port" "lan_access_point" {
  bridge    = routeros_interface_bridge.lan.name
  interface = routeros_interface_ethernet.access_point.name
  comment   = routeros_interface_ethernet.access_point.comment
  pvid      = "1"
}
resource "routeros_interface_bridge_port" "lan_truenas" {
  bridge    = routeros_interface_bridge.lan.name
  interface = routeros_interface_ethernet.truenas.name
  comment   = routeros_interface_ethernet.truenas.comment
  pvid      = "1"
}
resource "routeros_interface_bridge_port" "lan_home_assistant" {
  bridge    = routeros_interface_bridge.lan.name
  interface = routeros_interface_ethernet.home_assistant.name
  comment   = routeros_interface_ethernet.home_assistant.comment
  pvid      = "1"
}




## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_pool" "lan" {
  name = "lan-dhcp-pool"
  ranges = [ "192.168.69.100-192.168.69.199" ]
}
resource "routeros_ip_dhcp_server_network" "lan" {
  comment      = "LAN DHCP Server"
  domain       = "home.${local.local_domain}"
  address      = "192.168.69.0/24"
  gateway      = "192.168.69.1"
  dns_server   = "192.168.69.1"
  caps_manager = "192.168.69.1"
}
resource "routeros_ip_dhcp_server" "lan" {
  address_pool       = routeros_ip_pool.lan.name
  interface          = routeros_interface_bridge.lan.name
  name               = "LAN-dhcp"
  client_mac_limit   = 1
  conflict_detection = true
}




## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "lan_desktop" {
  address     = "192.168.69.69"
  mac_address = "74:56:3C:B7:9B:D8"
  server      = routeros_ip_dhcp_server.lan.name
  comment     = "Mircea Desktop PC"
}
resource "routeros_ip_dhcp_server_lease" "lan_access_point" {
  address     = "192.168.69.2"
  mac_address = "D4:01:C3:01:26:EC"
  server      = routeros_ip_dhcp_server.lan.name
  comment     = "Mikrotik cAP AX"
}
resource "routeros_ip_dhcp_server_lease" "lan_truenas" {
  address     = "192.168.69.254"
  mac_address = "E0:D5:5E:24:A1:EC"
  server      = routeros_ip_dhcp_server.lan.name
  comment     = "TrueNAS LAN"
}
resource "routeros_ip_dhcp_server_lease" "lan_home_assistant" {
  address     = "192.168.69.252"
  mac_address = "00:1E:06:42:C7:73"
  server      = routeros_ip_dhcp_server.lan.name
  comment     = "HomeAssistant"
}




## ================================================================================================
## DNS Records
## ================================================================================================
resource "routeros_ip_dns_record" "lan_self" {
  name    = "homebase.${routeros_ip_dhcp_server_network.lan.domain}"
  address = routeros_ip_dhcp_server_network.lan.gateway
  type    = "A"
}

resource "routeros_ip_dns_record" "lan_desktop" {
  name    = "mpadsk.${routeros_ip_dhcp_server_network.lan.domain}"
  address = routeros_ip_dhcp_server_lease.lan_desktop.address
  type    = "A"
}
resource "routeros_ip_dns_record" "lan_truenas" {
  name    = "truenas.${routeros_ip_dhcp_server_network.lan.domain}"
  address = routeros_ip_dhcp_server_lease.lan_truenas.address
  type    = "A"
}
resource "routeros_ip_dns_record" "lan_home_assistant" {
  name    = "homeassistant.${routeros_ip_dhcp_server_network.lan.domain}"
  address = routeros_ip_dhcp_server_lease.lan_home_assistant.address
  type    = "A"
}
resource "routeros_ip_dns_record" "lan_home_assistant2" {
  name            = "homeassistant.${routeros_ip_dhcp_server_network.lan.domain}"
  cname           = "hass.${routeros_ip_dhcp_server_network.lan.domain}"
  type            = "CNAME"
}
