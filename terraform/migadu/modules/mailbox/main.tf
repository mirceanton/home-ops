resource "migadu_mailbox" "mailbox" {
  name                    = var.name
  domain_name             = var.domain_name
  may_receive             = var.may_receive
  may_send                = var.may_send
  may_access_imap         = var.may_access_imap
  local_part              = var.local_part
  password_recovery_email = var.password_recovery_email
}

resource "migadu_alias" "aliases" {
  for_each = toset(var.aliases)

  domain_name  = var.domain_name
  local_part   = each.value
  destinations = ["${var.local_part}@${var.domain_name}"]
}
