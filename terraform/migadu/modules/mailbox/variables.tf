variable "name" {
  description = "Name of the mailbox (used for UI identification)"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the mailbox"
  type        = string
}

variable "may_receive" {
  description = "Whether the mailbox can receive emails"
  type        = bool
  default     = true
}

variable "may_send" {
  description = "Whether the mailbox can send emails"
  type        = bool
  default     = true
}

variable "may_access_imap" {
  description = "Whether the mailbox can be accessed via IMAP"
  type        = bool
  default     = true
}

variable "local_part" {
  description = "The local part of the email address (before @)"
  type        = string
}

variable "password_recovery_email" {
  description = "Email address for password recovery"
  type        = string
}

variable "aliases" {
  description = "List of aliases where each entry is a local part. Aliases will be mapped to the main mailbox local part."
  type        = list(string)
  default     = []
}
