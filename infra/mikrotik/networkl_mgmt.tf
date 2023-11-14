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
# TODO: static lease for truenas
# TODO: static lease for hkc-01
# TODO: static lease for hkc-02
# TODO: static lease for hkc-03
# TODO: static lease for utils
# TODO: static lease for lab server
# TODO: static lease for pikvm
