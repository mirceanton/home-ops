# =================================================================================================
# Email Routing Rule: Catch all and redirect
# =================================================================================================
resource "cloudflare_email_routing_catch_all" "catch_all" {
  zone_id = var.zone_id
  name    = "catchall forwarder"
  enabled = var.catchall.enabled

  matcher {
    type = "all"
  }

  action {
    type  = var.catchall.action_type
    value = var.catchall.action_targets
  }
}


# =================================================================================================
# Email Routing Rule: Granular
# =================================================================================================
resource "cloudflare_email_routing_rule" "granular" {
  for_each = var.granular.rules
  zone_id = var.zone_id
  name    = "terraform rule"
  enabled = each.enabled

  matcher {
    type  = each.matcher.type
    field = each.matcher.field
    value = each.matcher.value
  }

  action {
    type  = each.action.type
    value = each.action.value
  }
}
