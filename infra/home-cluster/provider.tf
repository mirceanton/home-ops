terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.11.0"
    }
	kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.23.0"
    }
	routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.25.0"
    }

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

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}


provider "helm" {
  kubernetes {
    config_path =  pathexpand("~/.kube/configs/${var.cluster_name}.yaml")
  }
}

provider "kubernetes" {
  config_path    =  pathexpand("~/.kube/configs/${var.cluster_name}.yaml")
}

provider "routeros" {
  hosturl  = var.mikrotik["hosturl"]
  username = var.mikrotik["username"]
  password = var.mikrotik["password"]
  insecure = var.mikrotik["insecure"]
}

