variable "zone_id" {
  type        = string
  description = "The Zone ID of the Cloudflare account where the redirect will be configured."
}

variable "redirect" {
  type = object({
    from        = string
    to          = string
    status_code = optional(number, 301)
    priority    = optional(number, 1)
  })
  description = "Configuration for URL redirection."
}
