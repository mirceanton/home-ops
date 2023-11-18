terraform {
  required_providers {
    # To interact with the Talos machines
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.4"
    }

    # To save the talosconfig and kubeconfig as local files
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }

    # To fetch the installer image name
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }
}
