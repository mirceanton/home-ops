variable "account_id" {
  type        = string
  description = "The Cloudflare account ID associated with the domain setup."
}

variable "domain" {
  type        = string
  description = "The domain name to be configured."
}

variable "dns_entries" {
  type        = list(object({
    id       = optional(string)
    name     = string
    value    = string
    type     = optional(string, "A")
    proxied  = optional(bool, true)
    priority = optional(number, 0)
    ttl      = optional(number, 1)
    comment  = optional(string, "")
  }))
  default     = []
  description = "List of DNS entries for the domain configuration."
}

variable "waf_custom_rules" {
  type        = list(object({
    enabled           = bool
    description       = string
    expression        = string
    action            = string
    action_parameters = optional(any, {})
    logging           = optional(any, {})
  }))
  default     = []
  description = "List of custom Web Application Firewall (WAF) rules for the domain."
}
