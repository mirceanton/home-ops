module "volsync_bucket" {
  source           = "./modules/minio_bucket"
  bucket_name      = var.volsync_bucket_name
  owner_access_key = var.volsync_bucket_access_key
  owner_secret_key = var.volsync_bucket_secret_key
  is_public        = false
}

output "volsync_bucket_outputs" {
  value     = module.volsync_bucket
  sensitive = true
}
