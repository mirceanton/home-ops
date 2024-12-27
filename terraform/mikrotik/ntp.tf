resource "routeros_system_ntp_server" "rb5009" {
  provider = routeros.rb5009

  enabled             = true
  broadcast           = true
  multicast           = true
  manycast            = true
  use_local_clock     = true
  local_clock_stratum = 3
}

resource "routeros_system_ntp_client" "rb5009" {
  provider = routeros.rb5009

  enabled = true
  mode    = "unicast"
  servers = ["89.36.19.21"]
}
resource "routeros_system_ntp_client" "crs317" {
  provider = routeros.crs317

  enabled = true
  mode    = "unicast"
  servers = ["192.168.88.1"]
}
resource "routeros_system_ntp_client" "crs326" {
  provider = routeros.crs326

  enabled = true
  mode    = "unicast"
  servers = ["192.168.88.1"]
}
