## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
import {
  to = routeros_interface_bridge.home
  id = "*C"
}
resource "routeros_interface_bridge" "home" {
  name           = "brHOME"
  vlan_filtering = true
}

import {
  to = routeros_ip_address.home
  id = "*2"
}
resource "routeros_ip_address" "home" {
  address   = "192.168.69.1/24"
  interface = routeros_interface_bridge.home.name
  network   = "192.168.69.0"
}


## ================================================================================================
## Bridge Ports
## ================================================================================================
import {
  to = routeros_interface_bridge_port.home_switch
  id = "*1"
}
resource "routeros_interface_bridge_port" "home_switch" {
  bridge    = routeros_interface_bridge.home.name
  interface = routeros_interface_ethernet.home.name
  comment   = routeros_interface_ethernet.home.comment
  pvid      = "1"
}
