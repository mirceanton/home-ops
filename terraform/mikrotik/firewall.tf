## ================================================================================================
## Interface Lists
## ================================================================================================
#################### EXPOSURE LEVEL GROUPING ####################
resource "routeros_interface_list" "external" { name = "external" }
resource "routeros_interface_list" "internal" { name = "internal" }

#################### TRUST LEVEL GROUPING ####################
resource "routeros_interface_list" "private_trusted" { name = "private_trusted" }
resource "routeros_interface_list" "private_untrusted" { name = "private_untrusted" }



## ================================================================================================
## NAT Rules
## ================================================================================================
resource "routeros_ip_firewall_nat" "nat" {
  action        = "masquerade"
  chain         = "srcnat"
  out_interface = routeros_interface_ethernet.wan.factory_name
}



## ================================================================================================
## Firewall Rules
## ================================================================================================
resource "routeros_ip_firewall_filter" "rule_1" {
  comment="defconf: accept established,related,untracked"
  chain = "input"
  action="accept"
  place_before = routeros_ip_firewall_filter.rule_2.id
}
resource "routeros_ip_firewall_filter" "rule_2" {
  comment="defconf: drop invalid"
  chain = "input"
  action="drop"
  connection_state="invalid"
  place_before = routeros_ip_firewall_filter.rule_3.id
}
resource "routeros_ip_firewall_filter" "rule_3" {
  comment="block untrusted -> trusted"
  chain = "forward"
  action="drop"
  src_address_list = "private_untrusted"
  dst_address_list = "private_trusted"
  place_before = routeros_ip_firewall_filter.rule_4.id
}
resource "routeros_ip_firewall_filter" "rule_4" {
  chain = "input"
  action="accept"
  protocol="icmp"
  comment="defconf: accept ICMP"
  place_before = routeros_ip_firewall_filter.rule_5.id
}
resource "routeros_ip_firewall_filter" "rule_5" {
  chain = "input"
  action="drop"
  in_interface_list="!internal"
  comment="defconf: drop all not coming from internal networks"
  place_before = routeros_ip_firewall_filter.rule_6.id
}
resource "routeros_ip_firewall_filter" "rule_6" {
  comment="defconf: fasttrack"
  chain = "forward"
  action="fasttrack-connection"
  connection_state="established,related"
  hw_offload = true
  place_before = routeros_ip_firewall_filter.rule_7.id
}
resource "routeros_ip_firewall_filter" "rule_7" {
  chain = "forward"
  action="accept"
  connection_state="established,related,untracked"
  comment="defconf: accept established,related, untracked"
  place_before = routeros_ip_firewall_filter.rule_8.id
}
resource "routeros_ip_firewall_filter" "rule_8" {
  chain = "forward"
  action="drop"
  connection_state="invalid"
  comment="defconf: drop invalid"
  place_before = routeros_ip_firewall_filter.rule_9.id
}
resource "routeros_ip_firewall_filter" "rule_9" {
  chain = "forward"
  action="drop"
  connection_state="new"
  connection_nat_state="!dstnat"
  in_interface_list="external"
  comment="defconf: drop all from external interfaces not DSTNATed"
}
