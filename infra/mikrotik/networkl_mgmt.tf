## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "mgmt_bridge" {
  name           = "brMGMT"
  vlan_filtering = true
}

resource "routeros_ip_address" "mgmt_address" {
  address   = "10.10.1.1/24"
  interface = routeros_interface_bridge.mgmt_bridge.name
  network   = "10.10.1.0"
}

resource "routeros_interface_bridge_port" "mgmt_bridge_port" {
  bridge    = routeros_interface_bridge.mgmt_bridge.name
  interface = routeros_interface_ethernet.mgmt_iface.name
  pvid      = "1"
  comment   = routeros_interface_ethernet.mgmt_iface.comment
}


## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_dhcp_server" "mgmt_dhcp" {
  address_pool     = routeros_ip_pool.mgmt_dhcp_pool.name
  interface        = routeros_interface_bridge.mgmt_bridge.name
  name             = "mgmt_dhcp"
  client_mac_limit = 1
}

resource "routeros_ip_dhcp_server_network" "mgmt_dhcp_network" {
  address    = "10.10.1.0/24"
  gateway    = split("/", routeros_ip_address.mgmt_address.address)[0]
  dns_server = split("/", routeros_ip_address.mgmt_address.address)[0]
  domain     = "mgmt.mirceanton.com"
}

resource "routeros_ip_pool" "mgmt_dhcp_pool" {
  name = "mgmt_dhcp_pool"
  ranges = [
    "10.10.1.190-10.10.1.199"
  ]
}


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "truenas_mgmt_lease" {
  address     = "10.10.1.245"
  mac_address = "70:4D:7B:2D:87:C9"
  server      = routeros_ip_dhcp_server.mgmt_dhcp.name
  comment     = "TrueNAS"
}
resource "routeros_ip_dhcp_server_lease" "bingus_mgmt_lease" {
  address     = "10.10.1.50"
  mac_address = "E0:D5:5E:24:A1:E4"
  server      = routeros_ip_dhcp_server.mgmt_dhcp.name
  comment     = "Bingus"
}

# resource "routeros_ip_dhcp_server_lease" "hkc_01_k8s_mgmt_lease" {
#   address     = "10.10.1.11"
#   mac_address = "70:85:C2:58:8D:31"
#   server = routeros_ip_dhcp_server.mgmt_dhcp.name
#   comment     = "2U Server"
# }
# resource "routeros_ip_dhcp_server_lease" "hkc_02_k8s_mgmt_lease" {
#   address     = "10.10.1.12"
#   mac_address = "D0:37:45:6F:22:29"
#   server = routeros_ip_dhcp_server.mgmt_dhcp.name
#   comment     = "MinisForum"
# }
# resource "routeros_ip_dhcp_server_lease" "hkc_02_k8s_mgmt_lease" {
#   address     = "10.10.1.12"
#   mac_address = "D0:37:45:6F:22:29"
#   server = routeros_ip_dhcp_server.mgmt_dhcp.name
#   comment     = "MinisForum"
# }

# TODO: static lease for hkc-03
# TODO: static lease for utils
# TODO: static lease for pikvm
