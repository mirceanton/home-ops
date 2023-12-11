output "bridge_name" {
  value = routeros_interface_bridge.network_bridge.name
}

output "dhcp_server_name" {
  value = routeros_ip_dhcp_server.network_dhcp.name
}
