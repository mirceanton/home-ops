variable "zone_id" {
  type = string
}
variable "account_id" {
  type = string
}
variable "pages_project_name" {
  type = string
}
variable "pages_project_domain" {
  type = string
}

variable "pages_project_repo" {
  type = object({
    type  = optional(string, "github"),
    owner = string,
    name  = string,

    production_branch            = optional(string, "main"),
    production_deployment_enable = optional(bool, true),
    preview_deployment_setting   = optional(string, "custom"),

    pr_comments_enable = optional(bool, true),
    deployments_enable = optional(bool, true),

    preview_branch_includes = list(string),
    preview_branch_excludes = list(string),

    build_command = string,
    build_dir     = string,
  })
}
