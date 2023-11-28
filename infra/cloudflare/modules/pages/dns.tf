# =================================================================================================
# Create the CNAME for root -> pages.dev
# =================================================================================================
resource "cloudflare_record" "root" {
  zone_id = var.zone_id

  name  = "@"
  type  = "CNAME"
  value = "${cloudflare_pages_project.pages_project.name}.pages.dev"

  comment = "Terraform Managed DNS entry."

  proxied         = true
  allow_overwrite = true
}

# =================================================================================================
# Create the CNAME for www -> pages.dev
# =================================================================================================
resource "cloudflare_record" "www" {
  zone_id = var.zone_id

  name  = "www"
  type  = "CNAME"
  value = "${cloudflare_pages_project.pages_project.name}.pages.dev"

  comment = "Terraform Managed DNS entry."

  proxied         = true
  allow_overwrite = true
}
