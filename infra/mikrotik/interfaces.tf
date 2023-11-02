resource "routeros_interface_ethernet" "desktop-iface" {
  factory_name = "ether1"
  name         = "desktop"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "wan-iface" {
  factory_name = "ether8"
  name         = "internet"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "switch-uplink-iface" {
  factory_name             = "sfp-sfpplus1"
  name                     = "core-switch"
  l2mtu                    = 1514
  sfp_shutdown_temperature = 90
}
