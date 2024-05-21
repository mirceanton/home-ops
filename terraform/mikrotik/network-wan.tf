resource "routeros_ip_dhcp_client" "wan" {
  interface = routeros_interface_ethernet.wan.name
  comment = "WAN DHCP Client"
}
