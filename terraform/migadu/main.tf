locals {
  domain = "mirceanton.com"
}

module "primary_domain_dns" {
  source              = "./modules/dns"
  domain_name         = "mirceanton.com"
  migadu_verification = var.migadu_verification_mirceanton
}
module "secondary_domain_dns" {
  source              = "./modules/dns"
  domain_name         = "mirceaanton.com"
  migadu_verification = var.migadu_verification_mirceaanton
}

module "personal_mailbox" {
  source                  = "./modules/mailbox"
  name                    = "Personal"
  domain_name             = local.domain
  may_receive             = true
  may_send                = true
  may_access_imap         = true
  local_part              = "mircea"
  password_recovery_email = var.migadu_api_email
  aliases                 = ["me", "personal"]
}

module "business_mailbox" {
  source                  = "./modules/mailbox"
  name                    = "Business"
  domain_name             = local.domain
  may_receive             = true
  may_send                = true
  may_access_imap         = true
  local_part              = "business"
  password_recovery_email = var.migadu_api_email
  aliases                 = ["contact"]
}

module "noreply_mailbox" {
  source                  = "./modules/mailbox"
  name                    = "NoReply"
  domain_name             = local.domain
  may_receive             = false
  may_send                = true
  may_access_imap         = false
  local_part              = "noreply"
  password_recovery_email = var.migadu_api_email
  aliases                 = []
}

module "spam_mailbox" {
  source                  = "./modules/mailbox"
  name                    = "Spam"
  domain_name             = local.domain
  may_receive             = true
  may_send                = false
  may_access_imap         = true
  local_part              = "spam"
  password_recovery_email = var.migadu_api_email
  aliases                 = []
}
