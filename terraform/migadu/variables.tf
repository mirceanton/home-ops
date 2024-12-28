# =================================================================================================
# Provider Configuration
# =================================================================================================
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
