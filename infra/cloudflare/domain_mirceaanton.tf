
module "domain_mirceaanton" {
  source     = "./modules/domain"
  domain     = "mirceaanton.com"
  account_id = cloudflare_account.mirceanton.id

  dns_entries = [
    # Generic settings
    {
      name    = "_dmarc"
      value   = "v=DMARC1; p=quarantine;"
      comment = "DMARC records"
      type    = "TXT"
    },

    # redirect to main domain
    {
      id    = "root_redirect",
      name  = "@",
      type  = "CNAME"
      value = "mirceanton.com"
    },
    {
      id    = "www_redirect",
      name  = "www",
      type  = "CNAME"
      value = "mirceanton.com"
    },
  ]

  waf_custom_rules = [
    {
      enabled     = true
      description = "Firewall rule to block bots and threats determined by CF"
      expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
      action      = "block"
    },
  ]
}

module "email_routing_mirceaanton" {
  source = "./modules/emails"

  account_id       = cloudflare_account.mirceanton.id
  zone_id          = module.domain_mirceaanton.zone_id
  target_addresses = [var.mirceanton_fwd_gmail]

  catchall = {
    enabled        = true,
    action_type    = "forward"
    action_targets = [var.mirceanton_fwd_gmail]
  }
}
