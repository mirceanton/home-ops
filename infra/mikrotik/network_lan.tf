module "lan_network" {
  source        = "./modules/mikrotik_network"

  base_domain = local.base_domain
  subdomain     = "lan"
  gateway_ip    = "192.168.69.1"
  dns_server_ip = "192.168.69.1"
  dhcp_server = {
    network = "192.168.69.0/24"
    start   = "192.168.69.10"
    end     = "192.168.69.199"
  }
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "lan_bridge_port" {
  bridge    = module.lan_network.bridge_name
  interface = routeros_interface_ethernet.lan_iface.name
  pvid      = "1"
  comment   = routeros_interface_ethernet.lan_iface.comment
}
resource "routeros_interface_bridge_port" "truenas_lan_bridge_port" {
  bridge    = module.lan_network.bridge_name
  interface = routeros_interface_ethernet.truenas_lan_iface.name
  pvid      = "1"
  comment   = routeros_interface_ethernet.truenas_lan_iface.comment
}
resource "routeros_interface_bridge_port" "bingus_lan_bridge_port" {
  bridge    = module.lan_network.bridge_name
  interface = routeros_interface_ethernet.bingus_lan_iface.name
  pvid      = "1"
  comment   = routeros_interface_ethernet.bingus_lan_iface.comment
}


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "desktop_pc_lease" {
  address     = "192.168.69.69"
  mac_address = "A8:A1:59:71:8B:B0"
  server      = module.lan_network.dhcp_server_name
  comment     = "NotANUC"
}
