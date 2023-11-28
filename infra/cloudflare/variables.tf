variable "cf_email" {
  type        = string
  description = "value"
  sensitive   = true
}

variable "cf_api_key" {
  type        = string
  description = "value"
  sensitive   = true
}

variable "mirceanton_discord_txt" {
  type        = string
  description = "value"
  sensitive   = true
}

variable "mirceanton_brevo_code" {
  type        = string
  description = "value"
  sensitive   = true
}
variable "mirceanton_brevo_dkim" {
  type        = string
  description = "value"
  sensitive   = true
}

variable "mirceanton_fwd_gmail" {
  type        = string
  description = "value"
}

variable "mirceanton_dmarc" {
  type      = string
  sensitive = true
}