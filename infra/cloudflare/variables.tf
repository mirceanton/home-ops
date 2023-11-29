# =================================================================================================
# CloudFlare Credentials
# =================================================================================================
variable "cf_email" {
  type        = string
  description = "Email address associated with the CloudFlare account."
  sensitive   = true
}

variable "cf_api_key" {
  type        = string
  description = "API key for authenticating with the CloudFlare API."
  sensitive   = true
}


# =================================================================================================
# Global Variables
# =================================================================================================
variable "gmail_address" {
  type        = string
  description = "Email address used for global configurations, such as notifications."
}

# =================================================================================================
# mirceanton Variables
# =================================================================================================
variable "mirceanton_discord_txt" {
  type        = string
  description = "Text for configuring Discord integration in the mirceanton environment."
  sensitive   = true
}

variable "mirceanton_brevo_code" {
  type        = string
  description = "Security code for the Brevo system in the mirceanton environment."
  sensitive   = true
}

variable "mirceanton_brevo_dkim" {
  type        = string
  description = "DKIM configuration for the Brevo system in the mirceanton environment."
  sensitive   = true
}

variable "mirceanton_dmarc" {
  type      = string
  description = "DMARC configuration for the mirceanton environment."
  sensitive = true
}

# =================================================================================================
# mirceaanton Variables
# =================================================================================================
variable "mirceaanton_dmarc" {
  type      = string
  description = "DMARC configuration for the mirceaanton environment."
  sensitive = true
}
