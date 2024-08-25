## ================================================================================================
## PPP Secret
## ================================================================================================
resource "random_password" "user_secret" {
  length  = 128
  special = true
}

resource "routeros_ppp_secret" "user" {
  name     = var.username
  comment  = "OpenVPN User"
  password = random_password.user_secret.result
  profile  = var.vpn_profile
}


## ================================================================================================
## Client Certificate
## ================================================================================================
resource "routeros_system_certificate" "client_crt" {
  name        = "OpenVPN-Client-Certificate-${var.username}"
  common_name = "Mikrotik OpenVPN Client ${var.username}"
  key_size    = "prime256v1"
  key_usage   = ["tls-client"]
  sign {
    ca = var.openvpn_ca_certificate_name
  }

  country      = "RO"
  state        = "B"
  locality     = "BUC"
  organization = "MIRCEANTON"
  unit         = "HOME"
  days_valid   = 3650 # 10 years
}
resource "random_password" "certificate_secret" {
  length  = 128
  special = true
}
# TODO: automate certificate export
# TODO: automate certificate download to tf runner
# TODO: automate certificate export to bitwarden
# TODO: automate ovpn config export


## ================================================================================================
## BitWarden Resources
## ================================================================================================
data "bitwarden_organization" "homelab" {
  search = var.bitwarden_organization_name
}

data "bitwarden_org_collection" "user_collection" {
  organization_id = data.bitwarden_organization.homelab.id
  search          = "Users/${var.username}"
}

resource "bitwarden_item_login" "vpn_credentials" {
  organization_id = data.bitwarden_organization.homelab.id
  collection_ids  = [data.bitwarden_org_collection.user_collection.id]

  name     = "OpenVPN"
  username = var.username
  password = random_password.user_secret.result

  field {
    name   = "Private Key Password"
    hidden = random_password.certificate_secret.result
  }
}
