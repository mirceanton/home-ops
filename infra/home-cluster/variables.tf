variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
}

variable "cluster_vip" {
  description = "The IP address of the VIP to be placed in front of the Talos API nodes."
  type        = object({
    ip = string,
    fqdn = string
  })
}

variable "cluster_service_lb" {
  description = "The IP address of the Kubernetes ingress controller."
  type        = object({
    ip = string,
    fqdn = string
  })
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
      install_disk      = string
      network_interface         = object({
        name = string,
        mac_address = string,
      }),
      system_extensions = list(string),
      fqdn        = string
    }))

    workers = map(object({
      install_disk      = string
      network_interface         = object({
        name = string,
        mac_address = string,
      }),
      system_extensions = list(string),
      fqdn        = string
    }))
  })
}

variable "mikrotik" {
  description = "Connection details for the mikoritk router"
  type = object({
    hosturl  = string,
    username = string,
    password = string,
    insecure = bool
  })
}