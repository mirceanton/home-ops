resource "routeros_system_ntp_server" "ntp" {
  enabled             = true
  broadcast           = true
  multicast           = true
  manycast            = true
  use_local_clock     = true
  local_clock_stratum = 3
}

resource "routeros_system_ntp_client" "ntp" {
  enabled = true
  mode    = "unicast"
  servers = ["89.36.19.21"]
}
