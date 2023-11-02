# resource "routeros_interface_vlan" "vlan_lan" {
#   interface = "bridge"
#   name      = "LAN"
#   comment   = "Local Network"
#   vlan_id   = 1969
# }

resource "routeros_interface_vlan" "vlan_dmz" {
  interface = "bridge"
  name      = "DMZ"
  comment   = "Unsafe Network"
  vlan_id   = 1742
}

resource "routeros_interface_vlan" "vlan_iot" {
  interface = "bridge"
  name      = "IOT"
  comment   = "IOT Crap"
  vlan_id   = 1769
}

resource "routeros_interface_vlan" "vlan_cluster" {
  interface = "bridge"
  name      = "K8S"
  comment   = "Cluster Network"
  vlan_id   = 1010
}

resource "routeros_interface_vlan" "vlan_mgmt" {
  interface = "bridge"
  name      = "MAN"
  comment   = "Management Network"
  vlan_id   = 1000
}

resource "routeros_interface_vlan" "vlan_lab" {
  interface = "bridge"
  name      = "LAB"
  comment   = "Lab Network"
  vlan_id   = 1020
}
