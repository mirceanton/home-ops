data "cloudflare_zone" "mirceaanton" {
  name = "mirceaanton.com"
}

# =================================================================================================
# Various TXT Verifications
# =================================================================================================
resource "cloudflare_record" "mirceaanton_TXT_verifications" {
  for_each = {
    "Google Verification" = {
      name    = "@",
      content = "\"${var.google_verification_mirceaanton}\""
    }
  }

  zone_id = data.cloudflare_zone.mirceaanton.id
  type    = "TXT"
  proxied = false

  name    = each.value.name
  comment = "Terraform: ${each.key}"
  content = each.value.content
}


# =================================================================================================
# GitHub Pages
# =================================================================================================
resource "cloudflare_record" "mirceaanton_redirects" {
  for_each = {
    "WWW"  = { name = "www", type = "CNAME", content = "mirceanton.com" },
    "Root" = { name = "@", type = "CNAME", content = "mirceanton.com" },
  }

  zone_id = data.cloudflare_zone.mirceaanton.id
  proxied = false

  type    = each.value.type
  name    = each.value.name
  content = each.value.content
  comment = "Terraform: Redirect ${each.key}"
}
