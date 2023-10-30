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
  direct_access_grants_enabled              = true
  service_accounts_enabled                  = false

  access_type         = "PUBLIC"
  valid_redirect_uris = ["*"]
}


# =================================================================================================
# OpenID Client Mappers
# =================================================================================================
# This mapper is used for the kubernetes apiserver integration
resource "keycloak_openid_user_client_role_protocol_mapper" "kubernetes-user_client_role_mapper" {
  realm_id = keycloak_realm.home.id
  client_id           = keycloak_openid_client.kubernetes-client.id

  name                = "groups"
  client_id_for_role_mappings = keycloak_openid_client.kubernetes-client.client_id
  client_role_prefix  = ""
  multivalued         = true
  claim_name          = "groups"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

# This mapper is needed for the oauth2 proxy integration
resource "keycloak_openid_audience_protocol_mapper" "kubernetes-audience_mapper" {
  realm_id                 = keycloak_realm.home.id
  client_id                = keycloak_openid_client.kubernetes-client.id
  name                     = "aud-mapper-oauth2-proxy"
  included_client_audience = keycloak_openid_client.kubernetes-client.client_id
  add_to_id_token          = true
  add_to_access_token      = true
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

resource "keycloak_role" "kubernetes-reader_role" {
  realm_id    = keycloak_realm.home.id
  client_id   = keycloak_openid_client.kubernetes-client.id
  name        = "reader"
  description = "Kubernetes Reader"
}
