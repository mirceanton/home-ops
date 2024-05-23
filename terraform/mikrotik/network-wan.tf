# Add wan port to public interface list
resource "routeros_interface_list_member" "public_wan" {
  list      = routeros_interface_list.public.name
  interface = routeros_interface_ethernet.wan.factory_name
}


# DHCP Client -> get IP from uplink
resource "routeros_ip_dhcp_client" "wan" {
  interface = routeros_interface_ethernet.wan
  comment   = "WAN DHCP Client"
}
