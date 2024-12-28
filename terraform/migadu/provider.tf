terraform {
  required_providers {
    migadu = {
      source  = "metio/migadu"
      version = "2024.12.26"
    }
  }
}

provider "migadu" {
  username = var.migadu_api_email
  token    = var.migadu_api_token
  timeout  = 35
  endpoint = "https://api.migadu.com/v1/"
}
