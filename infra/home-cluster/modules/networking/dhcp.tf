resource "routeros_ip_dhcp_server_lease" "controlplane_dhcp" {
  for_each = var.node_data.controlplanes

  address     = each.key
  mac_address = upper( each.value.network_interface.mac_address )
  comment     = each.value.fqdn
}

resource "routeros_ip_dhcp_server_lease" "worker_dhcp" {
  for_each = var.node_data.workers

  address     = each.key
  mac_address = upper( each.value.network_interface.mac_address )
  comment     = each.value.fqdn
}
