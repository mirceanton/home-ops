resource "cloudflare_pages_domain" "pages_domain" {
  account_id   = var.account_id
  project_name = cloudflare_pages_project.pages_project.name
  domain       = var.pages_project_domain
}
