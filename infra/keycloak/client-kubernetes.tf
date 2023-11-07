# =================================================================================================
# OpenID Client
# =================================================================================================
resource "keycloak_openid_client" "kubernetes" {
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

  access_type = "CONFIDENTIAL"
  root_url    = "https://kube-dashboard.${var.cluster_domain}"
  valid_redirect_uris = [
    "https://kube-dashboard.${var.cluster_domain}/oauth2/callback", # kube dashboard oauth redirect
    "http://localhost:*"                                            # kube apiserver oidc redirect
  ]
}


# =================================================================================================
# OpenID Client Mappers
# =================================================================================================
resource "keycloak_openid_user_client_role_protocol_mapper" "kubernetes-apiserver-mapper" {
  realm_id  = keycloak_realm.home.id
  client_id = keycloak_openid_client.kubernetes.id

  name                        = "groups"
  client_id_for_role_mappings = keycloak_openid_client.kubernetes.client_id
  client_role_prefix          = ""
  multivalued                 = true
  claim_name                  = "groups"
  claim_value_type            = "String"
  add_to_id_token             = true
  add_to_access_token         = true
  add_to_userinfo             = true
}

resource "keycloak_openid_audience_protocol_mapper" "kubernetes-dashboard-mapper" {
  realm_id                 = keycloak_realm.home.id
  client_id                = keycloak_openid_client.kubernetes.id
  name                     = "aud-mapper-oauth2-proxy"
  included_client_audience = keycloak_openid_client.kubernetes.client_id
  add_to_id_token          = true
  add_to_access_token      = true
}


# =================================================================================================
# OpenID Client Roles
# =================================================================================================
resource "keycloak_role" "kubernetes-admin" {
  realm_id    = keycloak_realm.home.id
  client_id   = keycloak_openid_client.kubernetes.id
  name        = "admin"
  description = "Kubernetes Administrator"
}

resource "keycloak_role" "kubernetes-reader" {
  realm_id    = keycloak_realm.home.id
  client_id   = keycloak_openid_client.kubernetes.id
  name        = "reader"
  description = "Kubernetes Reader"
}
