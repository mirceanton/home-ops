resource "routeros_interface_ethernet" "wan" {
  factory_name = "ether1"
  name         = "ether1"
  comment      = "WAN"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether2" {
  factory_name = "ether2"
  name         = "ether2"
  comment      = "N/A"
  disabled     = true
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether3" {
  factory_name = "ether3"
  name         = "ether3"
  comment      = "N/A"
  disabled     = true
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether4" {
  factory_name = "ether4"
  name         = "ether4"
  comment      = "N/A"
  disabled     = true
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether5" {
  factory_name = "ether5"
  name         = "ether5"
  comment      = "N/A"
  disabled     = true
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "cluster" {
  factory_name = "ether6"
  name         = "ether6"
  comment      = "Cluster Switch"
  disabled     = false
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "home" {
  factory_name = "ether7"
  name         = "ether7"
  comment      = "Home Switch"
  disabled     = false
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "management" {
  factory_name = "ether8"
  name         = "ether8"
  comment      = "Management Switch"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "sfp-sfpplus1" {
  factory_name             = "sfp-sfpplus1"
  name                     = "sfp-sfpplus1"
  comment                  = "N/A"
  l2mtu                    = 1514
  disabled                 = true
  sfp_shutdown_temperature = 90
}
