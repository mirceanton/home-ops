# =================================================================================================
# NAT Configuration
# =================================================================================================
import {
  to = routeros_ip_firewall_nat.nat_to_internet
  id = "*1"
}
resource "routeros_ip_firewall_nat" "nat_to_internet" {
  comment       = "NAT to Internet"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
  action        = "masquerade"
}
