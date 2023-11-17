variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster"
  type        = string
}

variable "cluster_vip" {
  description = "The IP address of the VIP to be placed in front of the Talos API nodes."
  type        = string
}

variable "talos_version" {
  description = "The version of Talos to install."
  type        = string
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to install."
  type        = string
}

variable "node_data" {
  description = "A map of node data"
  type = object({
    controlplanes = map(object({
      install_disk = string
      interface     = string
      system_extensions = list(string)
    }))
  
    workers = map(object({
      install_disk = string
      interface = string
      system_extensions = list(string)
    }))
  })
}