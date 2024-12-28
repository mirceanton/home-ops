data "cloudflare_zone" "mirceanton" {
  name = "mirceanton.com"
}

# =================================================================================================
# Various TXT Verifications
# =================================================================================================
resource "cloudflare_record" "mirceanton_TXT_verifications" {
  for_each = {
    "Discord Verification" = { name = "_discord.com", content = "\"${var.discord_verification_mirceanton}\"" },
    "Google Verification"  = { name = "mirceanton.com", content = "\"${var.google_verification_mirceanton}\"" }
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

    "Verification" = { name = "_github-pages-challenge-mirceanton", type = "TXT", content = "\"${var.github_verification_mirceanton}\"" }

    "A1" = { name = "mirceanton.com", type = "A", content = "185.199.111.153" }
    "A2" = { name = "mirceanton.com", type = "A", content = "185.199.110.153" }
    "A3" = { name = "mirceanton.com", type = "A", content = "185.199.109.153" }
    "A4" = { name = "mirceanton.com", type = "A", content = "185.199.108.153" }
  }

  zone_id = data.cloudflare_zone.mirceanton.id
  proxied = false

  type    = each.value.type
  name    = each.value.name
  content = each.value.content
  comment = "Terraform: ${each.key}"
}

# =================================================================================================
# Migadu
# =================================================================================================
resource "cloudflare_record" "mirceanton_migadu_TXT" {
  for_each = {
    "Verification" = { name = "mirceanton.com", content = "\"${var.migadu_verification_mirceanton}\"" }
    "SPF"          = { name = "mirceanton.com", content = "\"v=spf1 include:spf.migadu.com -all\"" }
    "DMARC"        = { name = "_dmarc", content = "\"v=DMARC1; p=quarantine;\"" }
  }
  zone_id = data.cloudflare_zone.mirceanton.id
  type    = "TXT"
  proxied = false

  name    = each.value.name
  content = each.value.content
  comment = "Terraform: Migadu ${each.key}"
}

resource "cloudflare_record" "mirceanton_migadu_CNAME" {
  for_each = {
    "DKIM Primary"           = { name = "key1._domainkey", content = "key1.mirceanton.com._domainkey.migadu.com" }
    "DKIM Secondary"         = { name = "key2._domainkey", content = "key2.mirceanton.com._domainkey.migadu.com" }
    "DKIM Tertiary"          = { name = "key3._domainkey", content = "key3.mirceanton.com._domainkey.migadu.com" }
    "Autoconfig Thunderbird" = { name = "autoconfig", content = "autoconfig.migadu.com" }
  }
  zone_id = data.cloudflare_zone.mirceanton.id
  type    = "CNAME"
  proxied = false

  name    = each.value.name
  content = each.value.content
  comment = "Terraform: Migadu ${each.key}"
}

resource "cloudflare_record" "mirceanton_migadu_SRV" {
  for_each = {
    "Autoconfig for Outlook" = { domain = "_autodiscover._tcp", priority = 0, weight = 1, port = 443, target = "autodiscover.migadu.com" }
    "Autoconfig SMTP"        = { domain = "_submissions._tcp", priority = 0, weight = 1, port = 465, target = "smtp.migadu.com" }
    "Autoconfig IMAP"        = { domain = "_imaps._tcp", priority = 0, weight = 1, port = 993, target = "imap.migadu.com" }
    "Autoconfig POP3"        = { domain = "_pop3s._tcp", priority = 0, weight = 1, port = 995, target = "pop3.migadu.com" }
  }
  zone_id = data.cloudflare_zone.mirceanton.id
  type    = "SRV"
  proxied = false

  name = each.value.domain
  data {
    priority = each.value.priority
    weight   = each.value.weight
    port     = each.value.port
    target   = each.value.target
  }
  comment = "Terraform: Migadu ${each.key}"
}

resource "cloudflare_record" "mirceanton_migadu_MX" {
  for_each = {
    "Primary MX Host"                          = { priority = 10, content = "aspmx1.migadu.com", name = "mirceanton.com" }
    "Secondary MX Host"                        = { priority = 20, content = "aspmx2.migadu.com", name = "mirceanton.com" }
    "Primary MX Host (Subdomain Addressing)"   = { priority = 10, content = "aspmx1.migadu.com", name = "*" }
    "Secondary MX Host (Subdomain Addressing)" = { priority = 20, content = "aspmx2.migadu.com", name = "*" }
  }

  zone_id = data.cloudflare_zone.mirceanton.id
  type    = "MX"
  proxied = false

  name     = each.value.name
  priority = each.value.priority
  content  = each.value.content
  comment  = "Terraform: Migadu ${each.key}"
}
