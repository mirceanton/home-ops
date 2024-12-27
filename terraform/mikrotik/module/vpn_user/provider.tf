terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.61.0"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "0.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
