resource "routeros_ip_dhcp_server_lease" "cluster_nodes" {
  for_each = { for node in var.nodes : node.mac_address => node }

  address     = each.value.ip_address
  mac_address = each.value.mac_address
  server      = var.dhcp_server_name
  comment     = each.value.hostname
}

resource "routeros_ip_dns_record" "cluster_service_lb_wildcards" {
  for_each = toset(var.service_lb.hostnames)

  regexp  = ".*.${each.value}"
  address = var.service_lb.ip_address
  type    = "A"
}

resource "routeros_ip_dns_record" "home_cluster_k8s_vip" {
  for_each = toset(var.vip.hostnames)

  name    = each.value
  address = var.vip.ip_address
  type    = "A"
}