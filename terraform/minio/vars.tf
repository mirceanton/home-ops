variable "minio_server" {
  type = string
}

variable "minio_user" {
  type = string
}

variable "minio_pass" {
  type = string
}

variable "minio_ssl" {
  type    = bool
  default = false
}

variable "volsync_bucket_name" {
  type = string
}
variable "volsync_bucket_access_key" {
  type      = string
  sensitive = false
  default   = null
}
variable "volsync_bucket_secret_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "cnpg_bucket_name" {
  type = string
}
variable "cnpg_bucket_access_key" {
  type      = string
  sensitive = false
  default   = null
}
variable "cnpg_bucket_secret_key" {
  type      = string
  sensitive = true
  default   = null
}