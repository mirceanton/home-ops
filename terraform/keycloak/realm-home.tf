# =================================================================================================
# Realm
# =================================================================================================
resource "keycloak_realm" "home" {
  realm             = "home"
  enabled           = true
  display_name      = "Home"
  display_name_html = "<b>Home</b>"

  login_theme = "keycloak"

  registration_allowed     = false
  edit_username_allowed    = true
  reset_password_allowed   = true
  remember_me              = true
  login_with_email_allowed = true
  duplicate_emails_allowed = false

  access_code_lifespan = "1h"

  password_policy = "upperCase(1) and length(16) and forceExpiredPasswordChange(365) and notUsername"

  attributes = {
    userProfileEnabled = true
  }

  smtp_server {
    host = var.smtp_host
    port = var.smtp_port

    from              = var.smtp_from_address
    from_display_name = var.smtp_from_name

    reply_to              = var.smtp_from_address
    reply_to_display_name = var.smtp_from_name

    starttls = var.smtp_starttls
    ssl      = var.smtp_ssl

    auth {
      username = var.smtp_user
      password = var.smtp_pass
    }
  }

  internationalization {
    supported_locales = ["en"]
    default_locale    = "en"
  }

  security_defenses {
    brute_force_detection {
      permanent_lockout                = false
      max_login_failures               = 30
      wait_increment_seconds           = 60
      quick_login_check_milli_seconds  = 1000
      minimum_quick_login_wait_seconds = 60
      max_failure_wait_seconds         = 900
      failure_reset_time_seconds       = 43200
    }
  }
}
