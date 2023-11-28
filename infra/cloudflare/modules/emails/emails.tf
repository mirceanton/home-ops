# =================================================================================================
# Enable CloudFlare Email Routing (note: this automatically configures the MX and TXT records)
# =================================================================================================
resource "cloudflare_email_routing_settings" "email_routing_enable" {
  zone_id = var.zone_id
  enabled = "true"
}

# =================================================================================================
# Email Routing Target -> personal Gmail
# =================================================================================================
resource "cloudflare_email_routing_address" "gmail" {
  account_id = var.account_id
  email      = var.forward_address
}


# =================================================================================================
# [DISABLED] Email Routing Rule: forward all emails to my personal gmail account
# =================================================================================================
resource "cloudflare_email_routing_catch_all" "catch_all" {
  zone_id = var.zone_id
  name    = "Gmail Forwarder"
  enabled = true

  matcher {
    type = "all"
  }

  action {
    type  = "forward"
    value = [var.forward_address]
  }
}
