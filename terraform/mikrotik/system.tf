resource "routeros_system_identity" "rb5009" {
  name = "MikroTik-RB5009"
}

resource "routeros_dns" "dns-server" {
  allow_remote_requests = true
  servers = [
    "1.1.1.1", "8.8.8.8",
  ]
}

resource "routeros_system_clock" "timezone" {
  time_zone_name = "Europe/Bucharest"
}

resource "routeros_tool_mac_server_winbox" "mac_server_winbox" {
  allowed_interface_list = "all"
}
