terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# =================================================================================================
# Cloudflare Page Rule for URL Redirect
# =================================================================================================
resource "cloudflare_page_rule" "page_rule_redirect" {
  zone_id  = var.zone_id
  target   = var.redirect.from
  priority = var.redirect.priority

  actions {
    forwarding_url {
      url         = var.redirect.to
      status_code = var.redirect.status_code
    }
  }
}

# =================================================================================================
# Cloudflare DNS Record for URL Redirect
# =================================================================================================
resource "cloudflare_record" "dns_record" {
  zone_id = var.zone_id

  name    = var.redirect.from
  type    = "CNAME"
  value   = trim(var.redirect.to, "https://")

  proxied = true
  comment = "[Terraform Managed] Redirect"
}
