# =================================================================================================
# Provider Configuration
# =================================================================================================
variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "API Token to authenticate against CloudFlare"
}
variable "migadu_api_token" {
  type        = string
  sensitive   = true
  description = "Token to authenticate against Migadu API"
}
variable "migadu_api_email" {
  type        = string
  sensitive   = true
  description = "Email to authenticate against Migadu API"
}


# =================================================================================================
# Domain Verifications
# =================================================================================================
variable "migadu_verification_mirceanton" {
  type        = string
  sensitive   = true
  description = "Content for the TXT record needed for Migadu verification."
}
variable "migadu_verification_mirceaanton" {
  type        = string
  sensitive   = true
  description = "Content for the TXT record needed for Migadu verification."
}
