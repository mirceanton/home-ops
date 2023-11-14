## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "lan_bridge" {
  name           = "brLAN"
  vlan_filtering = true
}

resource "routeros_ip_address" "lan_address" {
  address   = "192.168.69.1/24"
  interface = routeros_interface_bridge.lan_bridge.name
  network   = "192.168.69.0"
}

resource "routeros_interface_bridge_port" "lan_bridge_port" {
  bridge    = routeros_interface_bridge.lan_bridge.name
  interface = routeros_interface_ethernet.lan_iface.name
  pvid      = "1"
}


## ================================================================================================
## DHCP Server Config
## ================================================================================================
resource "routeros_ip_dhcp_server" "lan_dhcp" {
  address_pool     = routeros_ip_pool.lan_dhcp_pool.name
  interface        = routeros_interface_bridge.lan_bridge.name
  name             = "lan_dhcp"
  client_mac_limit = 1
}

resource "routeros_ip_dhcp_server_network" "lan_dhcp_network" {
  address    = "192.168.69.0/24"
  gateway    = split("/", routeros_ip_address.lan_address.address)[0]
  dns_server = split("/", routeros_ip_address.lan_address.address)[0]
  domain     = "home.mirceanton.com"
}

resource "routeros_ip_pool" "lan_dhcp_pool" {
  name = "lan_dhcp_pool"
  ranges = [
    "192.168.69.10-192.168.69.199"
  ]
}


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "desktop_pc_lease" {
  address     = "192.168.69.69"
  mac_address = "48:21:0B:50:EE:C2"
  server = routeros_ip_dhcp_server.lan_dhcp.name
  comment     = "Desktop Intel NUC"
}
