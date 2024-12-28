data "cloudflare_zone" "mirceaanton" {
  name = "mirceaanton.com"
}

# =================================================================================================
# Various TXT Verifications
# =================================================================================================
resource "cloudflare_record" "mirceaanton_TXT_verifications" {
  for_each = {
    "Google Verification" = { name = "mirceaanton.com", content = "\"${var.google_verification_mirceaanton}\"" }
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


# =================================================================================================
# Migadu
# =================================================================================================
resource "cloudflare_record" "mirceaanton_migadu_TXT" {
  for_each = {
    "Verification" = { name = "mirceaanton.com", content = "\"${var.migadu_verification_mirceaanton}\"" }
    "SPF"          = { name = "mirceaanton.com", content = "\"v=spf1 include:spf.migadu.com -all\"" }
    "DMARC"        = { name = "_dmarc", content = "\"v=DMARC1; p=quarantine;\"" }
  }
  zone_id = data.cloudflare_zone.mirceaanton.id
  type    = "TXT"
  proxied = false

  name    = each.value.name
  content = each.value.content
  comment = "Terraform: Migadu ${each.key}"
}

resource "cloudflare_record" "mirceaanton_migadu_CNAME" {
  for_each = {
    "DKIM Primary"           = { name = "key1._domainkey", content = "key1.mirceaanton.com._domainkey.migadu.com" }
    "DKIM Secondary"         = { name = "key2._domainkey", content = "key2.mirceaanton.com._domainkey.migadu.com" }
    "DKIM Tertiary"          = { name = "key3._domainkey", content = "key3.mirceaanton.com._domainkey.migadu.com" }
    "Autoconfig Thunderbird" = { name = "autoconfig", content = "autoconfig.migadu.com" }
  }
  zone_id = data.cloudflare_zone.mirceaanton.id
  type    = "CNAME"
  proxied = false

  name    = each.value.name
  content = each.value.content
  comment = "Terraform: Migadu ${each.key}"
}

resource "cloudflare_record" "mirceaanton_migadu_SRV" {
  for_each = {
    "Autoconfig for Outlook" = { domain = "_autodiscover._tcp", priority = 0, weight = 1, port = 443, target = "autodiscover.migadu.com" }
    "Autoconfig SMTP"        = { domain = "_submissions._tcp", priority = 0, weight = 1, port = 465, target = "smtp.migadu.com" }
    "Autoconfig IMAP"        = { domain = "_imaps._tcp", priority = 0, weight = 1, port = 993, target = "imap.migadu.com" }
    "Autoconfig POP3"        = { domain = "_pop3s._tcp", priority = 0, weight = 1, port = 995, target = "pop3.migadu.com" }
  }
  zone_id = data.cloudflare_zone.mirceaanton.id
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

resource "cloudflare_record" "mirceaanton_migadu_MX" {
  for_each = {
    "Primary MX Host"                          = { priority = 10, content = "aspmx1.migadu.com", name = "mirceaanton.com" }
    "Secondary MX Host"                        = { priority = 20, content = "aspmx2.migadu.com", name = "mirceaanton.com" }
    "Primary MX Host (Subdomain Addressing)"   = { priority = 10, content = "aspmx1.migadu.com", name = "*" }
    "Secondary MX Host (Subdomain Addressing)" = { priority = 20, content = "aspmx2.migadu.com", name = "*" }
  }

  zone_id = data.cloudflare_zone.mirceaanton.id
  type    = "MX"
  proxied = false

  name     = each.value.name
  priority = each.value.priority
  content  = each.value.content
  comment  = "Terraform: Migadu ${each.key}"
}
