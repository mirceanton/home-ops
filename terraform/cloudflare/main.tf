terraform {
  cloud {
    organization = "mirceanton"

    workspaces {
      name = "CloudFlare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.28.0"
    }
  }
}

provider "cloudflare" {
  email   = var.cf_email
  api_key = var.cf_api_key
}
