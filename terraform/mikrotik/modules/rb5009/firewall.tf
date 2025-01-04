# =================================================================================================
# NAT Rules
# https://registry.terraform.io/providers/terraform-routeros/routeros/latest/docs/resources/ip_firewall_nat
# =================================================================================================
resource "routeros_ip_firewall_nat" "wan" {
  comment            = "WAN masquerade"
  chain              = "srcnat"
  out_interface_list = "WAN"
  action             = "masquerade"
}
