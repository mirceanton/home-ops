module "iot_network" {
  source        = "./modules/mikrotik_network"

  base_domain = local.base_domain
  subdomain     = "iot"
  gateway_ip    = "172.16.69.1"
  dns_server_ip = "172.16.69.1"
  dhcp_server = {
    network = "172.16.69.0/24"
    start   = "10.0.10.190"
    end     = "10.0.10.199"
  }
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "iot_bridge_port" {
  bridge    = module.iot_network.bridge_name
  interface = routeros_interface_ethernet.iot_iface.name
  pvid      = "1"
  comment   = routeros_interface_ethernet.iot_iface.comment
}


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "homeassistant_lease" {
  address     = "172.16.69.9"
  mac_address = "00:1E:06:42:C7:73"
  server      = module.iot_network.dhcp_server_name
  comment     = "HomeAssistant"
}

resource "routeros_ip_dhcp_server_lease" "tplink_ap_lease" {
  address     = "172.16.69.2"
  mac_address = "EC:08:6B:46:52:D8"
  server      = module.iot_network.dhcp_server_name
  comment     = "TP-Link AC750 AP"
}

resource "routeros_ip_dhcp_server_lease" "mircea_s23_lease" {
  address     = "172.16.69.250"
  mac_address = "4A:C6:B6:F9:57:CD"
  server      = module.iot_network.dhcp_server_name
  comment     = "Mircea S23"
}
