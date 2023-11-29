# Redirect www -> root
resource "cloudflare_page_rule" "www_redirect" {
  count    = var.www_redirect_enabled ? 1 : 0
  zone_id  = var.zone_id
  target   = "www.${var.pages_project_domain}"
  priority = 1

  actions {
    forwarding_url {
      url         = "https://${var.pages_project_domain}"
      status_code = 301
    }
  }
}

resource "cloudflare_record" "pages_domain_www_dns" {
  count   = var.www_redirect_enabled ? 1 : 0
  zone_id = var.zone_id

  name  = "www"
  type  = "CNAME"
  value = "${var.pages_project_name}.pages.dev"

  proxied = true
  comment = trimspace("[Terraform Managed] CloudFlare Pages www redirection")
}
