## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "management" {
  name           = "brMANAGEMENT"
  vlan_filtering = false
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


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "management_odroid_c4" {
  address     = "10.0.0.11"
  mac_address = "00:1E:06:48:6A:28"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Odroid C4"
}
resource "routeros_ip_dhcp_server_lease" "management_hkc_01" {
  address     = "10.0.0.21"
  mac_address = "74:56:3C:99:5B:CE"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "HKC-01"
}
resource "routeros_ip_dhcp_server_lease" "management_hkc_02" {
  address     = "10.0.0.22"
  mac_address = "74:56:3C:B2:E5:A8"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "HKC 02"
}
resource "routeros_ip_dhcp_server_lease" "management_hkc_03" {
  address     = "10.0.0.23"
  mac_address = "74:56:3C:9E:BF:1A"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "HKC 03"
}
resource "routeros_ip_dhcp_server_lease" "management_truenas" {
  address     = "10.0.0.254"
  mac_address = "E0:D5:5E:24:A1:E4"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "TrueNAS"
}
resource "routeros_ip_dhcp_server_lease" "management_proxmox" {
  address     = "10.0.0.250"
  mac_address = "A8:A1:59:71:8B:B0"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Proxmox"
}
# resource "routeros_ip_dhcp_server_lease" "management_ap" {
#   address     = "10.0.0.5"
#   mac_address = ""
#   server      = routeros_ip_dhcp_server.management.name
#   comment     = "Mikrotik cAP AX"
# }


## ================================================================================================
## NAT Rules
## ================================================================================================
resource "routeros_ip_firewall_nat" "management" {
  comment       = "NAT Management Traffic"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
  action        = "masquerade"
  src_address   = "${routeros_ip_address.management.network}/24"
}
