resource "cloudflare_email_routing_address" "gmail" {
  for_each = var.target_addresses

  account_id = var.account_id
  email      = each.value
}