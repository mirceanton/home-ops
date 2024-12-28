variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "API Token to authenticate against CloudFlare"
}


variable "github_verification_mirceanton" {
  type        = string
  sensitive   = true
  description = "Content for the TXT record needed for GitHub Pages verification."
}
variable "google_verification_mirceanton" {
  type        = string
  sensitive   = true
  description = "Content for the TXT record needed for Google verification."
}
variable "google_verification_mirceaanton" {
  type        = string
  sensitive   = true
  description = "Content for the TXT record needed for Google verification."
}
variable "migadu_verification_mirceanton" {
  type        = string
  sensitive   = true
  description = "Content for the TXT record needed for Migadu verification."
}
variable "discord_verification_mirceanton" {
  type        = string
  sensitive   = true
  description = "Content for the TXT record needed for Discord verification."
}
