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