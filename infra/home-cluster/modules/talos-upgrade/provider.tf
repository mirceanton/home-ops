terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }

    # To fetch the installer image name
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }
}
