resource "cloudflare_account" "mirceanton" {
  name              = "Mircea Anton"
  type              = "standard"
  enforce_twofactor = false
}
