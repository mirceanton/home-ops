resource "routeros_interface_ethernet" "ether1" {
  factory_name = "ether1"
  name         = "ether1"
  comment      = "Desktop"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether2" {
  factory_name = "ether2"
  name         = "ether2"
  comment      = "K8S"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether3" {
  factory_name = "ether3"
  name         = "ether3"
  comment      = "MinisForum"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether4" {
  factory_name = "ether4"
  name         = "ether4"
  comment      = "N/A"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether5" {
  factory_name = "ether5"
  name         = "ether5"
  comment      = "N/A"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether6" {
  factory_name = "ether6"
  name         = "ether6"
  comment      = "N/A"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether7" {
  factory_name = "ether7"
  name         = "ether7"
  comment      = "IOT"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "ether8" {
  factory_name = "ether8"
  name         = "ether8"
  comment      = "WAN"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "sfp-sfpplus1" {
  factory_name             = "sfp-sfpplus1"
  name                     = "sfp-sfpplus1"
  comment                  = "N/A"
  l2mtu                    = 1514
  sfp_shutdown_temperature = 90
}