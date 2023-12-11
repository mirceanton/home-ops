module "mgmt_network" {
  source        = "./modules/mikrotik_network"

  base_domain = local.base_domain
  subdomain     = "mgmt"
  gateway_ip    = "10.10.1.1"
  dns_server_ip = "10.10.1.1"
  dhcp_server = {
    network = "10.10.1.0/24"
    start   = "10.10.1.190"
    end     = "10.10.1.199"
  }
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "mgmt_bridge_port" {
  bridge    = module.mgmt_network.bridge_name
  interface = routeros_interface_ethernet.mgmt_iface.name
  pvid      = "1"
  comment   = routeros_interface_ethernet.mgmt_iface.comment
}


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "truenas_mgmt_lease" {
  address     = "10.10.1.245"
  mac_address = "70:4D:7B:2D:87:C9"
  server      = module.mgmt_network.dhcp_server_name
  comment     = "TrueNAS"
}
resource "routeros_ip_dhcp_server_lease" "bingus_mgmt_lease" {
  address     = "10.10.1.50"
  mac_address = "E0:D5:5E:24:A1:E4"
  server      = module.mgmt_network.dhcp_server_name
  comment     = "Bingus"
}

# TODO: static lease for pikvm
