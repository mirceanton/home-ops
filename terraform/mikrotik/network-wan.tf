## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "wan" {
  name           = "brWAN"
  vlan_filtering = false
}

resource "routeros_interface_bridge_port" "wan" {
  bridge    = routeros_interface_bridge.wan.name
  interface = routeros_interface_ethernet.wan.name
  pvid      = "1"
}


## ================================================================================================
## DHCP Client Config
## ================================================================================================
resource "routeros_ip_dhcp_client" "wan" {
  interface = routeros_interface_bridge.wan.name
  comment   = "WAN DHCP Client"
}


## ================================================================================================
## NAT Configuration
## ================================================================================================
resource "routeros_ip_firewall_nat" "wan_default_nat" {
  action        = "masquerade"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
}


# ## ================================================================================================
# ## Firewall Rules
# ## ================================================================================================
# resource "routeros_ip_firewall_filter" "wan_rule_0" {
#   comment = "special dummy rule to show fasttrack counters"
#   action  = "passthrough"
#   chain   = "forward"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_1" {
#   comment          = "accept established,related,untracked"
#   action           = "accept"
#   chain            = "input"
#   connection_state = "established,related,untracked"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_2" {
#   comment          = "drop invalid"
#   action           = "drop"
#   chain            = "input"
#   connection_state = "invalid"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_3" {
#   comment  = "accept ICMP"
#   action   = "accept"
#   chain    = "input"
#   protocol = "icmp"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_4" {
#   comment     = "accept to local loopback (for CAPsMAN)"
#   action      = "accept"
#   chain       = "input"
#   dst_address = "127.0.0.1"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_5" {
#   comment           = "drop all not coming from LAN"
#   action            = "drop"
#   chain             = "input"
#   in_interface      = "!brLAN"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_6" {
#   comment      = "accept in ipsec policy"
#   action       = "accept"
#   chain        = "forward"
#   ipsec_policy = "in,ipsec"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_7" {
#   comment      = "accept out ipsec policy"
#   action       = "accept"
#   chain        = "forward"
#   ipsec_policy = "out,ipsec"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_8" {
#   comment          = "fasttrack"
#   action           = "fasttrack-connection"
#   hw_offload       = true
#   chain            = "forward"
#   connection_state = "established,related"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_9" {
#   comment          = "accept established,related, untracked"
#   action           = "accept"
#   chain            = "forward"
#   connection_state = "established,related,untracked"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_10" {
#   comment          = "drop invalid"
#   action           = "drop"
#   chain            = "forward"
#   connection_state = "invalid"
# }
# resource "routeros_ip_firewall_filter" "wan_rule_11" {
#   comment              = "drop all from WAN not DSTNATed"
#   action               = "drop"
#   chain                = "forward"
#   in_interface         = "brWAN"
#   connection_nat_state = "!dstnat"
# }
