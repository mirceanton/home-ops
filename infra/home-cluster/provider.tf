terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

provider "talos" {}

provider "local" {}

provider "http" {}

provider "null" {}
