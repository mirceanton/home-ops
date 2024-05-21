resource "routeros_interface_ethernet" "wan" {
  factory_name = "ether1"
  name         = "ether1"
  comment      = "WAN"
  l2mtu        = 1514

  advertise="100M-baseT-half,100M-baseT-full"
}
