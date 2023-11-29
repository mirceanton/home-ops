variable "zone_id" {
  type        = string
  description = "The Zone ID of the Cloudflare account where Cloudflare Pages will be configured."
}

variable "account_id" {
  type        = string
  description = "The Cloudflare account ID associated with the Cloudflare Pages configuration."
}

variable "pages_project_name" {
  type        = string
  description = "The name of the Cloudflare Pages project."
}

variable "pages_project_domain" {
  type        = string
  description = "The custom domain associated with the Cloudflare Pages project."
}

variable "www_redirect_enabled" {
  type        = bool
  default     = true
  description = "Enable or disable www to non-www redirect for the custom domain."
}

variable "pages_project_repo" {
  type = object({
    type                         = optional(string, "github")
    owner                        = string
    name                         = string
    production_branch            = optional(string, "main")
    production_deployment_enable = optional(bool, true)
    preview_deployment_setting   = optional(string, "custom")
    pr_comments_enable           = optional(bool, true)
    deployments_enable           = optional(bool, true)
    preview_branch_includes      = list(string)
    preview_branch_excludes      = list(string)
    build_command                = string
    build_dir                    = string
  })
  description = "Configuration settings for the Cloudflare Pages project repository."
}
