terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.49.1"
    }
    migadu = {
      source  = "metio/migadu"
      version = "2024.12.26"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "migadu" {
  username = var.migadu_api_email
  token    = var.migadu_api_token
  timeout  = 35
  endpoint = "https://api.migadu.com/v1/"
}
