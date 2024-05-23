## ================================================================================================
## Interface Lists
## ================================================================================================
# public facing interfaces -> insecure!!
resource "routeros_interface_list" "public" {
  name = "public"
}

# interfaces that can do whatever, they are trusted devices
resource "routeros_interface_list" "private_trusted" {
  name = "private_trusted"
}

# interfaces that can **only** access the internet
resource "routeros_interface_list" "private_untrusted" {
  name = "private_untrusted"
}



resource "routeros_ip_firewall_nat" "nat" {
  action        = "masquerade"
  chain         = "srcnat"
  out_interface = routeros_interface_ethernet.wan.factory_name
}


## ================================================================================================
## Firewall Rules
## ================================================================================================
# resource "routeros_ip_firewall_filter" "drop_other_forward" {
#   chain   = "forward"
#   action  = "drop"
#   comment = "Drop all other forward traffic"
# }
