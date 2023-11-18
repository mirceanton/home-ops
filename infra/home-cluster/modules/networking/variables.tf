variable "mikrotik" {
  type = object({
    hosturl  = string,
    username = string,
    password = string,
    insecure = bool
  })
}

variable "cluster_vip" {
  type = object({
    ip   = string,
    fqdn = string
  })
}

variable "cluster_service_lb" {
  type = object({
    ip   = string,
    fqdn = string
  })
}

variable "node_data" {
  description = "A map of node data"
  type = object({
    controlplanes = map(object({
      fqdn = string
      network_interface = object({
        mac_address = string,
      }),
    }))

    workers = map(object({
      fqdn = string
      network_interface = object({
        mac_address = string,
      }),
    }))
  })
}
