module "cnpg_bucket" {
  source           = "./modules/minio_bucket"
  bucket_name      = var.cnpg_bucket_name
  owner_access_key = var.cnpg_bucket_access_key
  owner_secret_key = var.cnpg_bucket_secret_key
  is_public        = false
}

output "cnpg_bucket_outputs" {
  value     = module.cnpg_bucket
  sensitive = true
}
