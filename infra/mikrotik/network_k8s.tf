## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "k8s_bridge" {
  name           = "brK8S"
  vlan_filtering = true
}

resource "routeros_ip_address" "k8s_address" {
  address   = "10.0.10.1/24"
  interface = routeros_interface_bridge.k8s_bridge.name
  network   = "10.0.10.0"
}

resource "routeros_interface_bridge_port" "k8s_bridge_port" {
  bridge    = routeros_interface_bridge.k8s_bridge.name
  interface = routeros_interface_ethernet.k8s_iface.name
  pvid      = "1"
  comment   = routeros_interface_ethernet.k8s_iface.comment
}


## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_dhcp_server" "k8s_dhcp" {
  address_pool     = routeros_ip_pool.k8s_dhcp_pool.name
  interface        = routeros_interface_bridge.k8s_bridge.name
  name             = "k8s_dhcp"
  client_mac_limit = 1
}
resource "routeros_ip_dhcp_server_network" "k8s_dhcp_network" {
  address    = "10.0.10.0/24"
  gateway    = split("/", routeros_ip_address.k8s_address.address)[0]
  dns_server = split("/", routeros_ip_address.k8s_address.address)[0]
  domain     = "k8s.mirceanton.com"
}

resource "routeros_ip_pool" "k8s_dhcp_pool" {
  name = "k8s_dhcp_pool"
  ranges = [
    "10.0.10.190-10.0.10.199"
  ]
}


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "k8s_switch_lease" {
  address     = "10.0.10.2"
  mac_address = "00:EE:AB:28:1C:81"
  server      = routeros_ip_dhcp_server.k8s_dhcp.name
  comment     = "Cisco SG350-10"
}

resource "routeros_ip_dhcp_server_lease" "hkc_01_k8s_lease" {
  address     = "10.0.10.11"
  mac_address = "48:21:0B:50:EE:C2"
  server      = routeros_ip_dhcp_server.k8s_dhcp.name
  comment     = "NUC-12 i5"
}
resource "routeros_ip_dhcp_server_lease" "hkc_02_k8s_lease" {
  address     = "10.0.10.12"
  mac_address = "70:85:C2:58:8D:31"
  server      = routeros_ip_dhcp_server.k8s_dhcp.name
  comment     = "2U server"
}
resource "routeros_ip_dhcp_server_lease" "hkc_03_k8s_lease" {
  address     = "10.0.10.13"
  mac_address = "1C:83:41:32:55:97"
  server      = routeros_ip_dhcp_server.k8s_dhcp.name
  comment     = "MinisForum"
}

# TODO: Lease for infra-01
