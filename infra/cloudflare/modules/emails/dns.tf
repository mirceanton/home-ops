# =================================================================================================
# TXT Record for Brevo
# =================================================================================================
resource "cloudflare_record" "brevo_code_txt" {
  zone_id = var.zone_id

  type  = "TXT"
  name  = "@"
  value = var.brevo_code

  comment = "Terraform Managed DNS Record for the Brevo Integration"

  allow_overwrite = true
}

# =================================================================================================
# TXT Record for Brevo
# =================================================================================================
resource "cloudflare_record" "brevo_dkim_txt" {
  zone_id = var.zone_id

  type  = "TXT"
  name  = "mail._domainkey"
  value = var.brevo_dkim

  comment = "Terraform Managed DNS Record for the Brevo Integration"

  allow_overwrite = true
}
