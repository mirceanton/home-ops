# =================================================================================================
# OpenID Client
# =================================================================================================
resource "keycloak_openid_client" "kubernetes-client" {
  realm_id      = keycloak_realm.home.id
  client_id     = var.kubernetes_client_id
  client_secret = var.kubernetes_client_secret

  name        = "Kubernetes"
  description = "Local Kubernetes Cluster Auth"
  enabled     = true

  standard_flow_enabled                     = true
  implicit_flow_enabled                     = false
  oauth2_device_authorization_grant_enabled = false
  direct_access_grants_enabled              = false
  service_accounts_enabled                  = false

  access_type         = "CONFIDENTIAL"
  valid_redirect_uris = ["*"]
}


# =================================================================================================
# OpenID Client Role Mapper
# =================================================================================================
resource "keycloak_openid_user_client_role_protocol_mapper" "kubernetes-user_client_role_mapper" {
  realm_id = keycloak_realm.home.id

  name                = "groups"
  client_id           = keycloak_openid_client.kubernetes-client.client_id
  client_role_prefix  = ""
  multivalued         = true
  claim_name          = "groups"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}


# =================================================================================================
# OpenID Client Roles
# =================================================================================================
resource "keycloak_role" "kubernetes-admin_role" {
  realm_id    = keycloak_realm.home.id
  client_id   = keycloak_openid_client.kubernetes-client.id
  name        = "admin"
  description = "Kubernetes Administrator"
}

resource "keycloak_role" "kubernetes-developer_role" {
  realm_id    = keycloak_realm.home.id
  client_id   = keycloak_openid_client.kubernetes-client.id
  name        = "developer"
  description = "Kubernetes Developer"
}

resource "keycloak_role" "kubernetes-reader_role" {
  realm_id    = keycloak_realm.home.id
  client_id   = keycloak_openid_client.kubernetes-client.id
  name        = "reader"
  description = "Kubernetes Reader"
}
