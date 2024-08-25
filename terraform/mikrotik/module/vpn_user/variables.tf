variable "username" {
  description = "The username of the VPN user"
  type        = string
}

variable "vpn_profile" {
  description = "The name of the PPP profile to use for the VPN user"
  type        = string
}

variable "bitwarden_organization_name" {
  description = "The name of the BitWarden organization to store the VPN user credentials"
  type        = string
}

variable "openvpn_ca_certificate_name" {
  description = "The name of the OpenVPN CA certificate"
  type        = string
}
