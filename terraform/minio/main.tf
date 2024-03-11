terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "2.1.0"
    }
  }
}

provider "minio" {
  minio_server   = var.minio_server
  minio_user     = var.minio_user
  minio_password = var.minio_pass
  minio_ssl      = var.minio_ssl
}
