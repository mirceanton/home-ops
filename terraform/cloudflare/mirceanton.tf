data "cloudflare_zone" "mirceanton" {
  name = "mirceanton.com"
}

# =================================================================================================
# Various TXT Verifications
# =================================================================================================
resource "cloudflare_record" "mirceanton_TXT_verifications" {
  for_each = {
    "Discord Verification" = {
      name    = "_discord.com",
      content = "\"${var.discord_verification_mirceanton}\""
    },
    "Google Verification" = {
      name    = "@",
      content = "\"${var.google_verification_mirceanton}\""
    }
  }

  zone_id = data.cloudflare_zone.mirceanton.id
  type    = "TXT"
  proxied = false

  name    = each.value.name
  comment = "Terraform: ${each.key}"
  content = each.value.content
}

# =================================================================================================
# GitHub Pages
# =================================================================================================
resource "cloudflare_record" "mirceanton_github_pages" {
  for_each = {
    "WWW" = { name = "www", type = "CNAME", content = "mirceanton.github.io" },

    "Verification" = {
      name    = "_github-pages-challenge-mirceanton",
      type    = "TXT",
      content = "\"${var.github_verification_mirceanton}\""
    }

    "A1" = { name = "@", type = "A", content = "185.199.111.153" }
    "A2" = { name = "@", type = "A", content = "185.199.110.153" }
    "A3" = { name = "@", type = "A", content = "185.199.109.153" }
    "A4" = { name = "@", type = "A", content = "185.199.108.153" }
  }

  zone_id = data.cloudflare_zone.mirceanton.id
  proxied = false

  type    = each.value.type
  name    = each.value.name
  content = each.value.content
  comment = "Terraform: GitHub Pages ${each.key}"
}
