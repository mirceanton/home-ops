variable "domain_name" {
  type        = string
  sensitive   = false
  description = "The domain name for the managed zone."
}

variable "migadu_verification" {
  type        = string
  sensitive   = true
  description = "Migadu verification code for TXT record"
}
