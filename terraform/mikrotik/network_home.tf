## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
import {
  to = routeros_interface_bridge.home
  id = "*C"
}
resource "routeros_interface_bridge" "home" {
  name           = "brHOME"
  vlan_filtering = true
}

import {
  to = routeros_ip_address.home
  id = "*2"
}
resource "routeros_ip_address" "home" {
  address   = "192.168.69.1/24"
  interface = routeros_interface_bridge.home.name
  network   = "192.168.69.0"
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
import {
  to = routeros_interface_bridge_port.home_switch
  id = "*1"
}
resource "routeros_interface_bridge_port" "home_switch" {
  bridge    = routeros_interface_bridge.home.name
  interface = routeros_interface_ethernet.home.name
  comment   = routeros_interface_ethernet.home.comment
  pvid      = "1"
}
resource "routeros_interface_bridge_port" "home_home_assistant" {
  bridge    = routeros_interface_bridge.home.name
  interface = routeros_interface_ethernet.home_assistant.name
  comment   = routeros_interface_ethernet.home_assistant.comment
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
# TODO static lease Gaming PC
# TODO static lease TrueNAS
# TODO static lease MikroTik AP


## ================================================================================================
## NAT Rules
## ================================================================================================
import {
  to = routeros_ip_firewall_nat.home
  id = "*8"
}
resource "routeros_ip_firewall_nat" "home" {
  comment       = "NAT Home Traffic"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
  action        = "masquerade"
  src_address   = "${routeros_ip_address.home.network}/24"
}
