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
  server = routeros_ip_dhcp_server.k8s_dhcp.name
  comment     = "Cisco SG350-10"
}
resource "routeros_ip_dhcp_server_lease" "truenas_k8s_lease" {
  address     = "10.0.10.245"
  mac_address = "00:1B:21:86:4F:CF"
  server = routeros_ip_dhcp_server.k8s_dhcp.name
  comment     = "TrueNAS"
}

resource "routeros_ip_dhcp_server_lease" "hkc_01_k8s_lease" {
  address     = "10.0.10.11"
  mac_address = "68:05:CA:C2:AD:FA"
  server = routeros_ip_dhcp_server.k8s_dhcp.name
  comment     = "2U server"
}
resource "routeros_ip_dhcp_server_lease" "minisforum_k8s_lease" {
  address     = "10.0.10.12"
  mac_address = "1C:83:41:32:55:97"
  server = routeros_ip_dhcp_server.k8s_dhcp.name
  comment     = "MinisForum"
}

# TODO: Lease for hkc-03
# TODO: Lease for infra-01
# TODO: Lease for storage server



## Firewall
resource "routeros_ip_firewall_filter" "block_k8s_to_lan_rule" {
  action      = "drop"
  chain       = "forward"
  src_address = routeros_ip_dhcp_server_network.k8s_dhcp_network.address
  dst_address = routeros_ip_dhcp_server_network.lan_dhcp_network.address
  comment = "Block all traffic from K8S to LAN"
}
resource "routeros_ip_firewall_filter" "block_k8s_to_iot_rule" {
  action      = "drop"
  chain       = "forward"
  src_address = routeros_ip_dhcp_server_network.k8s_dhcp_network.address
  dst_address = routeros_ip_dhcp_server_network.iot_dhcp_network.address
  comment = "Block all traffic from K8S to IOT"
}
resource "routeros_ip_firewall_filter" "block_k8s_to_mgmt_rule" {
  action      = "drop"
  chain       = "forward"
  src_address = routeros_ip_dhcp_server_network.k8s_dhcp_network.address
  dst_address = routeros_ip_dhcp_server_network.mgmt_dhcp_network.address
  comment = "Block all traffic from K8S to MGMT"
}
