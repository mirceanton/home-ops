terraform {
  required_providers {
    b2 = {
      source = "Backblaze/b2"
      version = "0.9.0"
    }
  }
}

provider "b2" {
  application_key = var.backblaze_application_key
  application_key_id = var.backblaze_application_key_id
}

