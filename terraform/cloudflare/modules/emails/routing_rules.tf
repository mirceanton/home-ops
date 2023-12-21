# =================================================================================================
# Email Routing Rule: Catch all and redirect
# =================================================================================================
resource "cloudflare_email_routing_catch_all" "catch_all" {
  zone_id = var.zone_id
  name    = "catchall"
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
  for_each = { for v in var.routing_rules : v => v }
  zone_id  = var.zone_id
  name     = "terraform rule"
  enabled  = each.value.enabled

  matcher {
    type  = each.value.matcher.type
    field = each.value.matcher.field
    value = each.value.matcher.value
  }

  action {
    type  = each.value.action.type
    value = each.value.action.value
  }
}
