resource "routeros_system_identity" "rb5009" {
  provider = routeros.rb5009
  name     = "Router"
}
resource "routeros_system_identity" "crs326" {
  provider = routeros.crs326
  name     = "Rack Slow"
}
resource "routeros_system_identity" "crs317" {
  provider = routeros.crs317
  name     = "Rack Fast"
}


resource "routeros_system_clock" "rb5009" {
  provider       = routeros.rb5009
  time_zone_name = "Europe/Bucharest"
}
resource "routeros_system_clock" "crs326" {
  provider       = routeros.crs326
  time_zone_name = "Europe/Bucharest"
}
resource "routeros_system_clock" "crs317" {
  provider       = routeros.crs317
  time_zone_name = "Europe/Bucharest"
}


resource "routeros_dns" "dns-server" {
  provider = routeros.rb5009

  allow_remote_requests = true
  servers = [
    "1.1.1.1", "8.8.8.8",
  ]
}

resource "routeros_tool_mac_server_winbox" "rb5009" {
  provider               = routeros.rb5009
  allowed_interface_list = "all"
}
resource "routeros_tool_mac_server" "rb5009" {
  provider               = routeros.rb5009
  allowed_interface_list = "all"
}
resource "routeros_tool_bandwidth_server" "rb5009" {
  provider = routeros.rb5009
  enabled  = false
}


resource "routeros_tool_mac_server_winbox" "crs317" {
  provider               = routeros.crs317
  allowed_interface_list = "all"
}
resource "routeros_tool_mac_server" "crs317" {
  provider               = routeros.crs317
  allowed_interface_list = "all"
}
resource "routeros_tool_bandwidth_server" "crs317" {
  provider = routeros.crs317
  enabled  = false
}


resource "routeros_tool_mac_server_winbox" "crs326" {
  provider               = routeros.crs326
  allowed_interface_list = "all"
}
resource "routeros_tool_mac_server" "crs326" {
  provider               = routeros.crs326
  allowed_interface_list = "all"
}
resource "routeros_tool_bandwidth_server" "crs326" {
  provider = routeros.crs326
  enabled  = false
}
