resource "minio_s3_bucket" "volsync_bucket" {
  bucket = "home-cluster-volsync"
  acl    = "public"
}

resource "minio_iam_user" "volsync_user" {
  name          = "home-cluster-volsync-restic"
  force_destroy = true
  tags = {
    cluster = "home-cluster"
    app     = "restic"
  }
}

resource "minio_iam_service_account" "volsync_service_account" {
  target_user = minio_iam_user.volsync_user.name
}

output "volsync_sa_access_key" {
  value = minio_iam_service_account.volsync_service_account.access_key
}

output "volsync_sa_secret_key" {
  value     = minio_iam_service_account.volsync_service_account.secret_key
  sensitive = true
}
