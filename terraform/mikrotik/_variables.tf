## ================================================================================================
## Mikrotik Variables
## ================================================================================================
variable "mikrotik_router_username" {
  type        = string
  default     = "admin"
  description = "The username to authenticate against the RouterOS API on the RB5009."
}
variable "mikrotik_router_password" {
  type        = string
  description = "The password to authenticate against the RouterOS API on the RB5009."
  sensitive   = true
}
variable "mikrotik_router_url" {
  type        = string
  description = "The URL for the RouterOS API on the RB5009."
}
variable "mikrotik_router_insecure_skip_tls_verify" {
  type        = bool
  default     = true
  description = "Whether or not to check for certificate validity"
}


## ================================================================================================
## BitWarden Variables
## ================================================================================================
variable "bitwarden_server_url" {
  type        = string
  description = "The URL for the BitWarden server."
  default     = "https://vault.bitwarden.com"
}
variable "bitwarden_email" {
  type        = string
  description = "The email address to authenticate against the BitWarden server."
  sensitive   = true
}
variable "bitwarden_client_id" {
  type        = string
  description = "The client ID to authenticate against the BitWarden server."
  sensitive   = true
}
variable "bitwarden_client_secret" {
  type        = string
  description = "The client secret to authenticate against the BitWarden server."
  sensitive   = true
}
variable "bitwarden_master_password" {
  type        = string
  description = "The master password to authenticate against the BitWarden server."
  sensitive   = true
}
