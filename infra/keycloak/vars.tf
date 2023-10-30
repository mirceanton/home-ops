# =================================================================================================
# Keycloak Connection Vars
# =================================================================================================
variable "keycloak_client_id" {
  type        = string
  default     = "admin-cli"
  description = "The client ID for the Keycloak client that will interact with the resources."
}

variable "keycloak_username" {
  type        = string
  default     = "admin"
  description = "The username or service account used to authenticate and interact with Keycloak."
}

variable "keycloak_password" {
  type        = string
  description = "The password or API key associated with the Keycloak username or service account."
}

variable "keycloak_url" {
  type        = string
  description = "The URL or endpoint of the Keycloak server for authentication and resource management."
}


# =================================================================================================
# SMTP Configuration Vars
# =================================================================================================
variable "smtp_host" {
  type        = string
  description = "The hostname or IP address of the SMTP server used for sending email notifications."
}

variable "smtp_port" {
  type        = number
  description = "The port number on the SMTP server for establishing the email connection (e.g., 25 for SMTP, 587 for SMTP with TLS)."
}

variable "smtp_user" {
  type        = string
  description = "The username or account for authenticating with the SMTP server, if required."
}

variable "smtp_pass" {
  type        = string
  description = "The password or API key associated with the SMTP username for authentication."
}

variable "smtp_starttls" {
  type        = bool
  description = "A boolean flag indicating whether to use the STARTTLS encryption protocol with the SMTP server (true or false)."
}

variable "smtp_ssl" {
  type        = bool
  description = "A boolean flag indicating whether to use SSL/TLS encryption with the SMTP server (true or false)."
}

variable "smtp_from_address" {
  type        = string
  description = "The email address from which email notifications will be sent."
}

variable "smtp_from_name" {
  type        = string
  description = "The display name associated with the sender's email address in email notifications."
}


# =================================================================================================
# Kubernetes OIDC Client Vars
# =================================================================================================
variable "kubernetes_client_secret" {
  type        = string
  description = "The client secret associated with the Kubernertes client for authentication."
}

variable "kubernetes_client_id" {
  type        = string
  description = "The client ID associated with the Kubernetes client for authentication."
}

# =================================================================================================
# Weave GitOps OIDC Client Vars
# =================================================================================================
variable "weave_gitops_client_secret" {
  type        = string
  description = "The client secret associated with the Weave GitOps client for authentication."
}

variable "weave_gitops_client_id" {
  type        = string
  description = "The client ID associated with the Weave GitOps client for authentication."
}
