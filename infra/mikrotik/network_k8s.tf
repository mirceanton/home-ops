module "k8s_network" {
  source        = "./modules/mikrotik_network"

  base_domain = local.base_domain
  subdomain     = "k8s"
  gateway_ip    = "10.0.10.1"
  dns_server_ip = "10.0.10.1"
  dhcp_server = {
    network = "10.0.10.0/24"
    start   = "10.0.10.190"
    end     = "10.0.10.199"
  }
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "k8s_bridge_port" {
  bridge    = module.k8s_network.bridge_name
  interface = routeros_interface_ethernet.k8s_iface.name
  pvid      = "1"
  comment   = routeros_interface_ethernet.k8s_iface.comment
}


## ================================================================================================
## Static DHCP Leases
## ================================================================================================
resource "routeros_ip_dhcp_server_lease" "k8s_switch_lease" {
  address     = "10.0.10.2"
  mac_address = "00:EE:AB:28:1C:81"
  server      = module.k8s_network.dhcp_server_name
  comment     = "Cisco SG350-10"
}


## ================================================================================================
## Home Cluster
## ================================================================================================
module "home_cluster" {
  source           = "./modules/k8s_cluster"
  dhcp_server_name = module.k8s_network.dhcp_server_name

  vip = {
    ip_address = "10.0.10.10"
    hostnames = [
      "home-cluster.k8s.mirceanton.com",
      "home-cluster.k8s.mirceaanton.com"
    ]
  }
  service_lb = {
    ip_address = "10.0.10.20"
    hostnames = [
      "homelab.mirceanton.com", "home.mirceanton.com",
      "homelab.mirceaanton.com", "home.mirceaanton.com"
    ]
  }
  nodes = [
    {
      mac_address = "48:21:0B:50:EE:C2"
      ip_address  = "10.0.10.11"
      hostname    = "hkc-01"
    },
    {
      mac_address = "70:85:C2:58:8D:31"
      ip_address  = "10.0.10.12"
      hostname    = "hkc-02"
    },
    {
      mac_address = "1C:83:41:32:55:97"
      ip_address  = "10.0.10.13"
      hostname    = "hkc-03"
    }
  ]
}


## ================================================================================================
## Infra Cluster
## ================================================================================================
module "infra_cluster" {
  source           = "./modules/k8s_cluster"
  dhcp_server_name = module.k8s_network.dhcp_server_name

  vip = {
    ip_address = "10.0.10.30"
    hostnames = [
      "infra-cluster.k8s.mirceanton.com",
      "infra-cluster.k8s.mirceaanton.com"
    ]
  }
  service_lb = {
    ip_address = "10.0.10.30"
    hostnames = [
      "infra.mirceanton.com",
      "infra.mirceaanton.com"
    ]
  }
  nodes = [
    {
      ip_address  = "10.0.10.31"
      mac_address = "00:A0:98:12:7B:F7"
      hostname    = "infra-01"
    }
  ]
}
