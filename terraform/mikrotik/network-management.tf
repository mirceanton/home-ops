## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "management" {
  name           = "brMAN"
  vlan_filtering = true
}
resource "routeros_ip_address" "management" {
  address   = "10.0.10.1/24"
  interface = routeros_interface_bridge.management.name
  network   = "10.0.10.0"
}


## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_dhcp_server" "management" {
  address_pool       = routeros_ip_pool.management.name
  interface          = routeros_interface_bridge.management.name
  name               = "MAN-dhcp"
  client_mac_limit   = 1
  conflict_detection = true
}
resource "routeros_ip_dhcp_server_network" "management" {
  address      = "10.0.10.0/24"
  caps_manager = "10.0.10.1"
  comment      = "Management DHCP Server Network"
  dns_server   = "10.0.10.1"
  domain       = "management.mirceanton.com"
  gateway      = "10.0.10.1"
}
resource "routeros_ip_pool" "management" {
  name = "management-dhcp-pool"
  ranges = [
    "10.0.10.190-10.0.10.199"
  ]
}
resource "routeros_ip_dhcp_server_lease" "cisco_sg350" {
  address     = "10.0.10.2"
  mac_address = "00:EE:AB:28:1C:81"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Management Switch - Cisco SG350-10"
}
resource "routeros_ip_dhcp_server_lease" "odroid_c4" {
  address     = "10.0.10.69"
  mac_address = "00:1E:06:48:6A:28"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Odroid C4"
}
resource "routeros_ip_dhcp_server_lease" "kube_01" {
  address     = "10.0.10.51"
  mac_address = "74:56:3C:9E:BF:1A"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Kube 01"
}
resource "routeros_ip_dhcp_server_lease" "kube_02" {
  address     = "10.0.10.52"
  mac_address = "74:56:3C:B2:E5:A8"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Kube 02"
}
resource "routeros_ip_dhcp_server_lease" "kube_03" {
  address     = "10.0.10.53"
  mac_address = "74:56:3C:99:5B:CE"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Kube 03"
}


## ================================================================================================
## DNS Records
## ================================================================================================
resource "routeros_ip_dns_record" "kube_01" {
  name    = "kube_01.${routeros_ip_dhcp_server_network.management.domain}"
  address = routeros_ip_dhcp_server_lease.kube_01.address
  type    = "A"
}
resource "routeros_ip_dns_record" "kube_02" {
  name    = "kube_02.${routeros_ip_dhcp_server_network.management.domain}"
  address = routeros_ip_dhcp_server_lease.kube_02.address
  type    = "A"
}
resource "routeros_ip_dns_record" "kube_03" {
  name    = "kube_03.${routeros_ip_dhcp_server_network.management.domain}"
  address = routeros_ip_dhcp_server_lease.kube_03.address
  type    = "A"
}
resource "routeros_ip_dns_record" "kubernetes_api" {
  name    = "kubernetes.${routeros_ip_dhcp_server_network.management.domain}"
  address = "10.0.10.50"
  type    = "A"
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "management" {
  bridge    = routeros_interface_bridge.management.name
  interface = routeros_interface_ethernet.management.name
  comment   = routeros_interface_ethernet.management.comment
  pvid      = "1"
}
