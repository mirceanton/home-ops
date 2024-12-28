data "cloudflare_zone" "mirceanton" {
  name = "mirceanton.com"
}

# =================================================================================================
# Discord Verification
# =================================================================================================
resource "cloudflare_record" "mirceanton_discord_verification" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "_discord"
  comment = "Terraform: Discord Verification"
  type    = "TXT"
  proxied = false
  content = "\"${var.discord_verification_mirceanton}\""
}


# =================================================================================================
# Google Verification
# =================================================================================================
resource "cloudflare_record" "mirceanton_google_verification" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "mirceanton.com"
  comment = "Terraform: Google Verification"
  type    = "TXT"
  proxied = false
  content = "\"${var.google_verification_mirceanton}\""
}

# =================================================================================================
# GitHub Pages
# =================================================================================================
resource "cloudflare_record" "mirceanton_github_pages" {
  for_each = toset(["185.199.111.153", "185.199.110.153", "185.199.109.153", "185.199.108.153"])

  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "mirceanton.com"
  comment = "Terraform: GitHub Pages"
  type    = "A"
  proxied = false
  content = each.value
}
resource "cloudflare_record" "mirceanton_github_pages_verification" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "_github-pages-challenge-mirceanton"
  comment = "Terraform: GitHub Pages"
  type    = "TXT"
  proxied = false
  content = "\"${var.github_verification_mirceanton}\""
}
resource "cloudflare_record" "mirceanton_github_pages_www" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "www"
  content = "mirceanton.github.io"
  comment = "Terraform: GitHub Pages"
  type    = "CNAME"
  proxied = false
}

# =================================================================================================
# Migadu
# =================================================================================================
resource "cloudflare_record" "mirceanton_migadu_verification" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "mirceanton.com"
  comment = "Terraform: Migadu Verification"
  type    = "TXT"
  proxied = false
  content = "\"${var.migadu_verification_mirceanton}\""
}
resource "cloudflare_record" "mirceanton_migadu_spf" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "mirceanton.com"
  comment = "Terraform: Migadu SPF"
  type    = "TXT"
  proxied = false
  content = "\"v=spf1 include:spf.migadu.com -all\""
}
resource "cloudflare_record" "mirceanton_migadu_dmarc" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "_dmarc"
  comment = "Terraform: Migadu DMARC"
  type    = "TXT"
  proxied = false
  content = "\"v=DMARC1; p=quarantine;\""
}
resource "cloudflare_record" "mirceanton_migadu_dkim" {
  for_each = toset(["key1", "key2", "key3"])

  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "${each.value}._domainkey"
  content = "${each.value}.mirceanton.com._domainkey.migadu.com"
  comment = "Terraform: Migadu DKIM"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "mirceanton_migadu_autoconfig_thunderbird" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "autoconfig"
  content = "autoconfig.migadu.com"
  comment = "Terraform: Migadu Autoconfig for Thunderbird"
  type    = "CNAME"
  proxied = false
}
resource "cloudflare_record" "mirceanton_migadu_autoconfig_outlook" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "_autodiscover._tcp"
  comment = "Terraform: Migadu Autoconfig for Outlook"
  proxied = false
  type    = "SRV"
  data {
    priority = 0
    weight   = 1
    port     = 443
    target   = "autodiscover.migadu.com"
  }
}
resource "cloudflare_record" "mirceanton_migadu_autoconfig_imap" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "_imaps._tcp"
  comment = "Terraform: Migadu Autoconfig IMAP"
  proxied = false
  type    = "SRV"
  data {
    priority = 0
    weight   = 1
    port     = 993
    target   = "imap.migadu.com"
  }
}
resource "cloudflare_record" "mirceanton_migadu_autoconfig_pop" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "_pop3s._tcp"
  comment = "Terraform: Migadu Autoconfig POP3"
  proxied = false
  type    = "SRV"
  data {
    priority = 0
    weight   = 1
    port     = 995
    target   = "pop.migadu.com"
  }
}
resource "cloudflare_record" "mirceanton_migadu_autoconfig_smtp" {
  zone_id = data.cloudflare_zone.mirceanton.id
  name    = "_submissions._tcp"
  comment = "Terraform: Migadu Autoconfig SMTP"
  proxied = false
  type    = "SRV"
  data {
    priority = 0
    weight   = 1
    port     = 465
    target   = "smtp.migadu.com"
  }
}


resource "cloudflare_record" "mirceanton_migadu_mx_domain_primary" {
  zone_id  = data.cloudflare_zone.mirceanton.id
  name     = "mirceanton.com"
  content  = "aspmx1.migadu.com"
  comment  = "Terraform: Migadu Primary MX Host (Subdomain Addressing)"
  type     = "MX"
  priority = 10
  proxied  = false
}
resource "cloudflare_record" "mirceanton_migadu_mx_domain_secondary" {
  zone_id  = data.cloudflare_zone.mirceanton.id
  name     = "mirceanton.com"
  content  = "aspmx2.migadu.com"
  comment  = "Terraform: Migadu Secondary MX Host (Subdomain Addressing)"
  type     = "MX"
  priority = 20
  proxied  = false
}
resource "cloudflare_record" "mirceanton_migadu_mx_subdomain_primary" {
  zone_id  = data.cloudflare_zone.mirceanton.id
  name     = "*"
  content  = "aspmx1.migadu.com"
  comment  = "Terraform: Migadu Primary MX Host (Subdomain Addressing)"
  type     = "MX"
  priority = 10
  proxied  = false
}
resource "cloudflare_record" "mirceanton_migadu_mx_subdomain_secondary" {
  zone_id  = data.cloudflare_zone.mirceanton.id
  name     = "*"
  content  = "aspmx2.migadu.com"
  comment  = "Terraform: Migadu Secondary MX Host (Subdomain Addressing)"
  type     = "MX"
  priority = 20
  proxied  = false
}
