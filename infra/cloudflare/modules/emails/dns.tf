resource "cloudflare_record" "dns_records" {
  for_each = { for dns_entry in var.dns_entries : (dns_entry.id != null ? dns_entry.id : "${dns_entry.name}_${dns_entry.priority}") => dns_entry }

  zone_id  = var.zone_id
  name     = each.value.name
  value    = each.value.value
  priority = each.value.priority
  proxied  = contains(["A", "CNAME"], each.value.type) ? each.value.proxied : false
  type     = each.value.type
  ttl      = each.value.ttl

  comment = trimspace("[Terraform Managed DNS Record] ${each.value.comment}")
}
