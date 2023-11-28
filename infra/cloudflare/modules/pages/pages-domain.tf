resource "cloudflare_pages_domain" "pages_domain" {
  account_id   = var.account_id
  project_name = cloudflare_pages_project.pages_project.name
  domain       = var.pages_project_domain
}

resource "cloudflare_record" "pages_domain_dns" {
  zone_id = var.zone_id

  name  = "@"
  type  = "CNAME"
  value = "${var.pages_project_name}.pages.dev"

  proxied = true
  comment = trimspace("[Terraform Managed] CloudFlare Pages")
}
