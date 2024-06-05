## ================================================================================================
## Interface Configuration
## ================================================================================================
resource "routeros_interface_list_member" "management_trusted" {
  list      = routeros_interface_list.private_trusted.name
  interface = routeros_interface_ethernet.management.factory_name
}
resource "routeros_interface_list_member" "management_internal" {
  list      = routeros_interface_list.internal.name
  interface = routeros_interface_ethernet.management.factory_name
}

resource "routeros_ip_address" "management" {
  interface = routeros_interface_ethernet.management.factory_name
  address   = "10.0.10.1/24"
  network   = "10.0.10.0"
}




## ================================================================================================
## DHCP Server Configuration
## ================================================================================================
resource "routeros_ip_pool" "management" {
  name = "management-dhcp-pool"
  ranges = [ "10.0.10.190-10.0.10.199" ]
}
resource "routeros_ip_dhcp_server_network" "management" {
  comment      = "Management DHCP Server Network"
  domain       = "mgmt.${local.local_domain}"
  address      = "10.0.10.0/24"
  gateway      = "10.0.10.1"
  dns_server   = "10.0.10.1"
  caps_manager = "10.0.10.1"
}
resource "routeros_ip_dhcp_server" "management" {
  interface          = routeros_interface_ethernet.management.factory_name
  address_pool       = routeros_ip_pool.management.name
  name               = "MGMT-dhcp"
  client_mac_limit   = 1
  conflict_detection = true
}




## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "mgmt_cisco_sg350" {
  address     = "10.0.10.2"
  mac_address = "00:EE:AB:28:1C:81"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Management Switch - Cisco SG350-10"
}
resource "routeros_ip_dhcp_server_lease" "mgmt_odroid_c4" {
  address     = "10.0.10.69"
  mac_address = "00:1E:06:48:6A:28"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Odroid C4"
}
resource "routeros_ip_dhcp_server_lease" "mgmt_proxmox" {
  address     = "10.0.10.99"
  mac_address = "A8:A1:59:71:8B:B0"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "PVE"
}
resource "routeros_ip_dhcp_server_lease" "mgmt_kube_01" {
  address     = "10.0.10.51"
  mac_address = "74:56:3C:9E:BF:1A"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Kube 01"
}
resource "routeros_ip_dhcp_server_lease" "mgmt_kube_02" {
  address     = "10.0.10.52"
  mac_address = "74:56:3C:B2:E5:A8"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Kube 02"
}
resource "routeros_ip_dhcp_server_lease" "mgmt_kube_03" {
  address     = "10.0.10.53"
  mac_address = "74:56:3C:99:5B:CE"
  server      = routeros_ip_dhcp_server.management.name
  comment     = "Kube 03"
}




## ================================================================================================
## DNS Records
## ================================================================================================
resource "routeros_ip_dns_record" "mgmt_self" {
  name    = "homebase.${routeros_ip_dhcp_server_network.management.domain}"
  address = routeros_ip_dhcp_server_network.management.gateway
  type    = "A"
}

# Random Devices
resource "routeros_ip_dns_record" "mgmt_cisco_sg350" {
  name    = "cisco-sg350.${routeros_ip_dhcp_server_network.management.domain}"
  address = routeros_ip_dhcp_server_lease.mgmt_cisco_sg350.address
  type    = "A"
}
resource "routeros_ip_dns_record" "mgmt_odroid_c4" {
  name    = "odroid-c4.${routeros_ip_dhcp_server_network.management.domain}"
  address = routeros_ip_dhcp_server_lease.mgmt_odroid_c4.address
  type    = "A"
}
resource "routeros_ip_dns_record" "mgmt_pve" {
  name    = "proxmox.${routeros_ip_dhcp_server_network.management.domain}"
  address = routeros_ip_dhcp_server_lease.mgmt_proxmox.address
  type    = "A"
}

# Kubernetes Cluster Stuff
resource "routeros_ip_dns_record" "mgmt_kubernetes_api" {
  name    = "home-cluster.${routeros_ip_dhcp_server_network.management.domain}"
  address = "10.0.10.50"
  type    = "A"
}
resource "routeros_ip_dns_record" "mgmt_kube_01" {
  name    = "kube-01.${routeros_ip_dns_record.mgmt_kubernetes_api.name}"
  address = routeros_ip_dhcp_server_lease.mgmt_kube_01.address
  type    = "A"
}
resource "routeros_ip_dns_record" "mgmt_kube_02" {
  name    = "kube_02.${routeros_ip_dns_record.mgmt_kubernetes_api.name}"
  address = routeros_ip_dhcp_server_lease.mgmt_kube_02.address
  type    = "A"
}
resource "routeros_ip_dns_record" "mgmt_kube_03" {
  name    = "kube_03.${routeros_ip_dns_record.mgmt_kubernetes_api.name}"
  address = routeros_ip_dhcp_server_lease.mgmt_kube_03.address
  type    = "A"
}
