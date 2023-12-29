module "volsync_bucket" {
  source           = "./modules/minio_bucket"
  bucket_name      = vars.volsync_bucket_name
  owner_access_key = vars.volsync_bucket_access_key
  owner_secret_key = vars.volsync_bucket_secret_key
  is_public        = false
}

output "volsync_bucket_outputs" {
  value     = module.volsync_bucket
  sensitive = true
}


module "cnpg_bucket" {
  source           = "./modules/minio_bucket"
  bucket_name      = vars.cnpg_bucket_name
  owner_access_key = vars.cnpg_bucket_access_key
  owner_secret_key = vars.cnpg_bucket_secret_key
  is_public        = false
}

output "cnpg_bucket_outputs" {
  value     = module.cnpg_bucket
  sensitive = true
}
