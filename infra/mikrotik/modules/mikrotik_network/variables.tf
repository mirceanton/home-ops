variable "base_domain" {
  description = "Base domain name for the network"
  type        = string
}

variable "subdomain" {
  description = "Subdomain name for the network"
  type        = string
}

variable "gateway_ip" {
  description = "Gateway IP address for the network"
  type        = string
}

variable "dns_server_ip" {
  description = "DNS server IP address for the network"
  type        = string
}

variable "dhcp_server" {
  description = "DHCP server configuration for the network"
  type        = map(string)
}
