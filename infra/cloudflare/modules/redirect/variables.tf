variable "zone_id" {
  type = string
}

variable "redirect" {
  type = object({
    from        = string,
    to          = string,
    status_code = optional(number, 301)
    priority    = optional(number, 1)
  })
}