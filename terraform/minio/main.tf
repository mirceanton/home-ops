terraform {
  cloud {
    organization = "mirceanton"

    workspaces {
      name = "MinIO"
    }
  }
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "2.0.1"
    }
  }
}

provider "minio" {
  minio_server   = var.minio_server
  minio_user     = var.minio_user
  minio_password = var.minio_pass
  minio_ssl      = var.minio_ssl
}
