resource "routeros_interface_bridge" "k8s_bridge" {
  name           = "brK8S"
  vlan_filtering = true
}

resource "routeros_ip_address" "k8s_address" {
  address   = "10.0.10.1/24"
  interface = routeros_interface_bridge.k8s_bridge.name
  network   = "10.0.10.1"
}

resource "routeros_interface_bridge_port" "k8s_bridge_port" {
  bridge    = routeros_interface_bridge.k8s_bridge.name
  interface = "ether2"
  pvid      = "1"
}

resource "routeros_ip_pool" "k8s_dhcp_pool" {
  name = "k8s_dhcp_pool"
  ranges = [
    "10.0.10.190-10.0.10.199"
  ]
}
resource "routeros_ip_dhcp_server_network" "k8s_dhcp_network" {
  address    = "10.0.10.0/24"
  gateway    = split("/", routeros_ip_address.k8s_address.address)[0]
  dns_server = split("/", routeros_ip_address.k8s_address.address)[0]
  domain     = "k8s.mirceanton.com"
}
resource "routeros_ip_dhcp_server" "k8s_dhcp" {
  address_pool     = routeros_ip_pool.k8s_dhcp_pool.name
  interface        = routeros_interface_bridge.k8s_bridge.name
  name             = "k8s_dhcp"
  client_mac_limit = 1
}

# TODO: Lease for hkc-01
# TODO: Lease for hkc-02
# TODO: Lease for hkc-03
# TODO: Lease for infra-01
# TODO: Lease for storage server
