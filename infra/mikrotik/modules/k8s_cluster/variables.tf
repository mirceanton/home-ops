variable "nodes" {
  description = "List of nodes in the cluster"
  type = list(object({
    ip_address  = string
    mac_address = string
    hostname    = string
  }))
}

variable "vip" {
  description = "K8S Virtual IP configuration for the cluster"
  type = object({
    ip_address = string,
    hostnames  = list(string)
  })
}

variable "service_lb" {
  description = "Service LB Virtual IP configuration for the cluster"
  type = object({
    ip_address = string,
    hostnames  = list(string)
  })
}

variable "dhcp_server_name" {
  type        = string
  description = "The name of the DHCP server to which the leases belong to."
}
