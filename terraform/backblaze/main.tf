resource "b2_bucket" "obsidian_sync" {
  bucket_name = "mirceanton-obsidian-sync"
  bucket_type = "allPrivate"

  lifecycle_rules {
    file_name_prefix              = ""
    days_from_hiding_to_deleting  = 1
    days_from_uploading_to_hiding = 0
  }
}

resource "b2_bucket" "truenas_backups" {
  bucket_name = "mirceanton-truenas-backup"
  bucket_type = "allPrivate"

  lifecycle_rules {
    file_name_prefix              = ""
    days_from_hiding_to_deleting  = 1
    days_from_uploading_to_hiding = 0
  }
}
