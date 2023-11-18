resource "routeros_ip_dns_record" "cluster_vip_dns" {
  name    = var.cluster_vip.fqdn
  address = var.cluster_vip.ip
  type    = "A"
}

resource "routeros_ip_dns_record" "cluster_ingress_dns" {
  name    = var.cluster_service_lb.fqdn
  address = var.cluster_service_lb.ip
  type    = "A"

}
resource "routeros_ip_dns_record" "controlplane_dns" {
  for_each = var.node_data.controlplanes

  name    = each.value.fqdn
  address = each.key
  type    = "A"
}

resource "routeros_ip_dns_record" "worker_dns" {
  for_each = var.node_data.workers

  name    = each.value.fqdn
  address = each.key
  type    = "A"
}
