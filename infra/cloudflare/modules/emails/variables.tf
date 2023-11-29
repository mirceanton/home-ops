variable "zone_id" {
  type        = string
  description = "The Zone ID of the Cloudflare account where email redirection will be configured."
}

variable "account_id" {
  type        = string
  description = "The Cloudflare account ID associated with the email redirection configuration."
}

variable "target_addresses" {
  type        = set(string)
  description = "Set of email addresses to which the incoming emails will be redirected."
}

variable "catchall" {
  type = object({
    enabled        = optional(bool, true)
    action_type    = optional(string, "forward")
    action_targets = optional(list(string), [""])
  })
  description = "Configuration for catch-all email forwarding, if enabled."
}

variable "routing_rules" {
  type = list(object({
    enabled = optional(bool, true),
    matcher = object({
      type  = optional(string, "all")
      field = string
      value = string
    })
    action = object({
      type  = string
      value = string
    })
  }))
  description = "List of routing rules for custom email redirection based on specific criteria."
}

variable "dns_entries" {
  type = list(object({
    id       = optional(string)
    name     = string
    value    = string
    type     = optional(string, "A")
    proxied  = optional(bool, true)
    priority = optional(number, 0)
    ttl      = optional(number, 1)
    comment  = optional(string, "")
  }))
  description = "List of DNS entries for email redirection configuration."
}
