## Bridge Network Configuration
resource "routeros_interface_bridge" "network_bridge" {
  name           = "br${upper(var.subdomain)}"
  vlan_filtering = true
}

resource "routeros_ip_address" "network_address" {
  address   = "${var.gateway_ip}/24"
  interface = routeros_interface_bridge.network_bridge.name
  network   = split("/", var.dhcp_server.network)[0]
}


## DHCP Server Config
resource "routeros_ip_dhcp_server" "network_dhcp" {
  address_pool     = routeros_ip_pool.network_dhcp_pool.name
  interface        = routeros_interface_bridge.network_bridge.name
  name             = "${var.subdomain}-dhcp"
  client_mac_limit = 1
}

resource "routeros_ip_dhcp_server_network" "network_dhcp_network" {
  address    = var.dhcp_server.network
  gateway    = var.gateway_ip
  dns_server = var.dns_server_ip
  domain     = "${var.subdomain}.${var.base_domain}"
}

resource "routeros_ip_pool" "network_dhcp_pool" {
  name   = "${var.subdomain}-dhcp"
  ranges = ["${var.dhcp_server.start}-${var.dhcp_server.end}"]
}
