variable "zone_id" {
  type        = string
}

variable "account_id" {
  type        = string
}

variable "forward_address" {
  type        = string
}

variable "brevo_dkim" {
  type        = string
  description = "DKIM TXT Record for the Brevo Integration"
}

variable "brevo_code" {
  type        = string
  description = "BrevoCode TXT Record for the Brevo Integration"
}
