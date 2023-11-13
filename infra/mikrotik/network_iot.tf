resource "routeros_interface_bridge" "iot_bridge" {
  name           = "brIOT"
  vlan_filtering = true
}

resource "routeros_ip_address" "iot_address" {
  address   = "172.16.69.1/24"
  interface = routeros_interface_bridge.iot_bridge.name
  network   = "172.16.69.0"
}

resource "routeros_interface_bridge_port" "iot_bridge_port" {
  bridge    = routeros_interface_bridge.iot_bridge.name
  interface = routeros_interface_ethernet.iot_iface.name
  pvid      = "1"
}

resource "routeros_ip_pool" "iot_dhcp_pool" {
  name = "iot_dhcp_pool"
  ranges = [
    "172.16.69.10-172.16.69.249"
  ]
}
resource "routeros_ip_dhcp_server_network" "iot_dhcp_network" {
  address    = "172.16.69.0/24"
  gateway    = split("/", routeros_ip_address.iot_address.address)[0]
  dns_server = split("/", routeros_ip_address.iot_address.address)[0]
  domain     = "iot.mirceanton.com"
}
resource "routeros_ip_dhcp_server" "iot_dhcp" {
  address_pool     = routeros_ip_pool.iot_dhcp_pool.name
  interface        = routeros_interface_bridge.iot_bridge.name
  name             = "iot_dhcp"
  client_mac_limit = 1
}


resource "routeros_ip_dhcp_server_lease" "homeassistant_lease" {
  address     = "172.16.69.9"
  mac_address = "00:1E:06:42:C7:73"
  comment = "HomeAssistant"
}
