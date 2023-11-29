# =================================================================================================
# DNS Zone + Records + WAF
# =================================================================================================
module "domain_mirceaanton" {
  source     = "./modules/domain"
  domain     = "mirceaanton.com"
  account_id = cloudflare_account.mirceanton.id

  waf_custom_rules = [
    {
      enabled     = true
      description = "Firewall rule to block bots and threats determined by CF"
      expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
      action      = "block"
    },
  ]
}


# =================================================================================================
# CloudFlare eMail Routing
# =================================================================================================
module "email_routing_mirceaanton" {
  source = "./modules/emails"

  account_id       = cloudflare_account.mirceanton.id
  zone_id          = module.domain_mirceaanton.zone_id
  target_addresses = [var.gmail_address]

  catchall = {
    enabled        = true,
    action_type    = "forward"
    action_targets = [var.gmail_address]
  }

  dns_entries = [
    {
      name    = "_dmarc"
      value   = var.mirceaanton_dmarc
      comment = "DMARC Record"
      type    = "TXT"
    }
  ]
}


# =================================================================================================
# Redirect secondary domain to mirceanton.com
# =================================================================================================
module "mirceaanton_redirect_to_mirceanton" {
  source  = "./modules/redirect"
  zone_id = module.domain_mirceaanton.zone_id
  redirect = {
    from     = "mirceaanton.com"
    to       = "https://mirceanton.com"
    priority = 1
  }
}
module "mirceaanton_www_redirect_to_mirceanton" {
  source  = "./modules/redirect"
  zone_id = module.domain_mirceaanton.zone_id
  redirect = {
    from     = "www.mirceaanton.com"
    to       = "https://mirceanton.com"
    priority = 2
  }
}
