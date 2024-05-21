resource "routeros_interface_ethernet" "wan" {
  factory_name = "ether1"
  name         = "ether1"
  comment      = "WAN"
  l2mtu        = 1514

  advertise="100M-baseT-half,100M-baseT-full"
}

resource "routeros_interface_ethernet" "desktop" {
  factory_name = "ether2"
  name         = "ether2"
  comment      = "desktop"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "access_point" {
  factory_name = "ether3"
  name         = "ether3"
  comment      = "cAP"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "truenas" {
  factory_name = "ether4"
  name         = "ether4"
  comment      = "TrueNAS"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "home_assistant" {
  factory_name = "ether5"
  name         = "ether5"
  comment      = "HomeAssistant"
  l2mtu        = 1514
}

resource "routeros_interface_ethernet" "management" {
  factory_name = "ether8"
  name         = "ether8"
  comment      = "Management"
  l2mtu        = 1514
}
