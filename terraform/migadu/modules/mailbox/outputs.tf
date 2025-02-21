output "mailbox_id" {
  description = "The ID of the created mailbox"
  value       = migadu_mailbox.mailbox.id
}

output "aliases" {
  description = "The aliases created for the mailbox"
  value       = toset([for alias in migadu_alias.aliases : alias.id])
}
