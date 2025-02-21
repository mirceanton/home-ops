# =================================================================================================
# DNS Zone
# =================================================================================================
data "cloudflare_zone" "zone" {
  name = var.domain_name
}

# =================================================================================================
# DNS Records
# =================================================================================================
resource "cloudflare_record" "TXT" {
  for_each = {
    "Verification" = { name = "@", content = "\"${var.migadu_verification}\"" }
    "SPF"          = { name = "@", content = "\"v=spf1 include:spf.migadu.com -all\"" }
    "DMARC"        = { name = "_dmarc", content = "\"v=DMARC1; p=quarantine;\"" }
  }
  zone_id = data.cloudflare_zone.zone.id
  type    = "TXT"
  proxied = false

  name    = each.value.name
  content = each.value.content
  comment = "Terraform: Migadu ${each.key}"
}

resource "cloudflare_record" "CNAME" {
  for_each = {
    "DKIM Primary"           = { name = "key1._domainkey", content = "key1.${var.domain_name}._domainkey.migadu.com" }
    "DKIM Secondary"         = { name = "key2._domainkey", content = "key2.${var.domain_name}._domainkey.migadu.com" }
    "DKIM Tertiary"          = { name = "key3._domainkey", content = "key3.${var.domain_name}._domainkey.migadu.com" }
    "Autoconfig Thunderbird" = { name = "autoconfig", content = "autoconfig.migadu.com" }
  }
  zone_id = data.cloudflare_zone.zone.id
  type    = "CNAME"
  proxied = false

  name    = each.value.name
  content = each.value.content
  comment = "Terraform: Migadu ${each.key}"
}

resource "cloudflare_record" "SRV" {
  for_each = {
    "Autoconfig for Outlook" = { name = "_autodiscover._tcp", port = 443, target = "autodiscover.migadu.com" }
    "Autoconfig SMTP"        = { name = "_submissions._tcp", port = 465, target = "smtp.migadu.com" }
    "Autoconfig IMAP"        = { name = "_imaps._tcp", port = 993, target = "imap.migadu.com" }
    "Autoconfig POP3"        = { name = "_pop3s._tcp", port = 995, target = "pop3.migadu.com" }
  }
  zone_id = data.cloudflare_zone.zone.id
  type    = "SRV"
  proxied = false

  name = each.value.name
  data {
    priority = 0
    weight   = 1
    port     = each.value.port
    target   = each.value.target
  }
  comment = "Terraform: Migadu ${each.key}"
}

resource "cloudflare_record" "mirceaanton_migadu_MX" {
  for_each = {
    "Primary MX Host"                          = { priority = 10, content = "aspmx1.migadu.com", name = "@" }
    "Secondary MX Host"                        = { priority = 20, content = "aspmx2.migadu.com", name = "@" }
    "Primary MX Host (Subdomain Addressing)"   = { priority = 10, content = "aspmx1.migadu.com", name = "*" }
    "Secondary MX Host (Subdomain Addressing)" = { priority = 20, content = "aspmx2.migadu.com", name = "*" }
  }
  zone_id = data.cloudflare_zone.zone.id
  type    = "MX"
  proxied = false

  name     = each.value.name
  priority = each.value.priority
  content  = each.value.content
  comment  = "Terraform: Migadu ${each.key}"
}
