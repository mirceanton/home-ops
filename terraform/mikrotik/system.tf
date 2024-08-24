resource "routeros_system_identity" "rb5009" {
  name = "MikroTik-RB5009"
}

resource "routeros_system_clock" "timezone" {
  time_zone_name = "Europe/Bucharest"
}
