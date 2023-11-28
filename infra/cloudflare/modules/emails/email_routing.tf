resource "cloudflare_email_routing_settings" "email_routing_enable" {
  zone_id = var.zone_id
  enabled = "true"
}