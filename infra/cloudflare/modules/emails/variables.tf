variable "zone_id" {
  type = string
}

variable "account_id" {
  type = string
}

variable "target_addresses" {
  type = set(string)
}

variable "catchall" {
  type = object({
    enabled        = optional(bool, true)
    action_type    = optional(string, "forward")
    action_targets = optional(list(string), [""])
  })
  default = {}
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
  default = []
}

variable "dns_entries" {
  type = list(object({
    id       = optional(string)
    name     = string,
    value    = string,
    type     = optional(string, "A"),
    proxied  = optional(bool, true),
    priority = optional(number, 0),
    ttl      = optional(number, 1)
    comment  = optional(string, "")
  }))
  default = []
}
