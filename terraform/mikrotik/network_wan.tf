## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "wan" {
  name           = "brWAN"
  vlan_filtering = false
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
resource "routeros_interface_bridge_port" "wan_uplink" {
  bridge    = routeros_interface_bridge.wan.name
  interface = routeros_interface_ethernet.wan.name
  comment   = routeros_interface_ethernet.wan.comment
  pvid      = "1"
}


## ================================================================================================
## PPPoE Client Config
## ================================================================================================
resource "routeros_interface_pppoe_client" "wan" {
  disabled  = false
  interface = routeros_interface_ethernet.wan.name
  name      = "PPPoE Digi"
  user      = var.pppoe_client_user
  password  = var.pppoe_client_pass
}
