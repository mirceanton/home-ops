resource "cloudflare_pages_project" "pages_project" {
  account_id        = var.account_id
  name              = var.pages_project_name
  production_branch = var.pages_project_repo.production_branch

  source {
    type = var.pages_project_repo.type
    config {
      owner                         = var.pages_project_repo.owner
      repo_name                     = var.pages_project_repo.name
      production_branch             = var.pages_project_repo.production_branch
      pr_comments_enabled           = var.pages_project_repo.pr_comments_enable
      deployments_enabled           = var.pages_project_repo.deployments_enable
      production_deployment_enabled = var.pages_project_repo.production_deployment_enable
      preview_deployment_setting    = var.pages_project_repo.preview_deployment_setting
      preview_branch_includes       = var.pages_project_repo.preview_branch_includes
      preview_branch_excludes       = var.pages_project_repo.preview_branch_excludes
    }
  }

  build_config {
    build_command   = var.pages_project_repo.build_command
    destination_dir = var.pages_project_repo.build_dir
  }
}
