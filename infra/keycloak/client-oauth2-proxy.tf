# =================================================================================================
# OpenID Client
# =================================================================================================
resource "keycloak_openid_client" "oauth2-proxy_client" {
  realm_id      = keycloak_realm.home.id
  client_id     = var.oauth2_proxy_client_id
  client_secret = var.oauth2_proxy_client_secret

  name    = "OAuth2 Proxy"
  enabled = true

  standard_flow_enabled                     = true
  implicit_flow_enabled                     = false
  oauth2_device_authorization_grant_enabled = false
  direct_access_grants_enabled              = false
  service_accounts_enabled                  = false

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = ["*"]
}


# =================================================================================================
# OpenID Client Audience Mapper
# =================================================================================================
resource "keycloak_openid_audience_protocol_mapper" "oauth2-proxy_audience-mapper" {
  realm_id                 = keycloak_realm.home.id
  client_id                = keycloak_openid_client.oauth2-proxy_client.id
  name                     = "aud-mapper-oauth2-proxy"
  included_client_audience = keycloak_openid_client.oauth2-proxy_client.client_id
  add_to_id_token          = true
  add_to_access_token      = true
}
