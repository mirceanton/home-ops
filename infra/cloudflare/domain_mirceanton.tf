module "domain_mirceanton" {
  source = "./modules/domain"

  domain     = "mirceanton.com"
  account_id = cloudflare_account.mirceanton.id
  dns_entries = [
    # Generic settings
    {
      name    = "_dmarc"
      value   = var.mirceanton_dmarc
      comment = "DMARC Record"
      type    = "TXT"
    },
    {
      id      = "discord_txt",
      name    = "_discord",
      type    = "TXT"
      comment = "Discord Domain Verification"
      value   = var.mirceanton_discord_txt
    },
    {
      id      = "brevo_code",
      name    = "@"
      type    = "TXT"
      comment = "Brevo Integration"
      value   = var.mirceanton_brevo_code
    },
    {
      id      = "brevo_dkim",
      name    = "mail._domainkey"
      type    = "TXT"
      comment = "Brevo Integration"
      value   = var.mirceanton_brevo_dkim
    },
    {
      id      = "pages_root",
      name    = "@"
      type    = "CNAME"
      comment = "CloudFlare Pages"
      value   = "mirceanton.pages.dev"
    },
    {
      id      = "pages_www",
      name    = "www"
      type    = "CNAME"
      comment = "CloudFlare Pages"
      value   = "mirceanton.pages.dev"
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

module "email_routing_mirceanton" {
  source = "./modules/emails"

  zone_id          = module.domain_mirceanton.zone_id
  account_id       = cloudflare_account.mirceanton.id
  target_addresses = [var.mirceanton_fwd_gmail]

  catchall = {
    enabled        = true,
    action_type    = "forward"
    action_targets = [var.mirceanton_fwd_gmail]
  }
}

module "cloudflare_pages_mirceanton" {
  source               = "./modules/pages"
  zone_id              = module.domain_mirceanton.zone_id
  account_id           = cloudflare_account.mirceanton.id
  pages_project_name   = "mirceanton"
  pages_project_domain = "mirceanton.com"

  pages_project_repo = {
    type  = "github"
    owner = "mirceanton"
    name  = "mirceanton.com"

    preview_branch_includes = ["post/*"]
    preview_branch_excludes = ["main"]

    build_command = "npm run build"
    build_dir     = "public"
  }
}
