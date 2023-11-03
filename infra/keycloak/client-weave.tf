# =================================================================================================
# OpenID Client
# =================================================================================================
resource "keycloak_openid_client" "weave-gitops" {
  realm_id      = keycloak_realm.home.id
  client_id     = var.weave_gitops_client_id
  client_secret = var.weave_gitops_client_secret

  name        = "Weave GitOps"
  description = "Weave GitOps Dashboard SSO"
  enabled     = true

  standard_flow_enabled                     = true
  implicit_flow_enabled                     = false
  oauth2_device_authorization_grant_enabled = false
  direct_access_grants_enabled              = true
  service_accounts_enabled                  = false

  access_type = "CONFIDENTIAL"
  root_url    = "https://gitops.${var.cluster_domain}"
  valid_redirect_uris = [
    "https://gitops.${var.cluster_domain}/oauth2/callback"
  ]
}


# =================================================================================================
# OpenID Client Mappers
# =================================================================================================
resource "keycloak_openid_user_client_role_protocol_mapper" "weave-dashboard-group-mapper" {
  realm_id  = keycloak_realm.home.id
  client_id = keycloak_openid_client.weave-gitops.id

  name                        = "groups"
  client_id_for_role_mappings = keycloak_openid_client.weave-gitops.client_id
  client_role_prefix          = ""
  multivalued                 = true
  claim_name                  = "groups"
  claim_value_type            = "String"
  add_to_id_token             = true
  add_to_access_token         = true
  add_to_userinfo             = true
}


# =================================================================================================
# OpenID Client Roles
# =================================================================================================
resource "keycloak_role" "weave-admin" {
  realm_id    = keycloak_realm.home.id
  client_id   = keycloak_openid_client.weave-gitops.id
  name        = "wego-admin"
  description = "GitOps ReadWrite Role"
}
