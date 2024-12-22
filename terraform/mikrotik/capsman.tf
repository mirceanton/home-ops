resource "routeros_wifi_capsman" "settings" {
  enabled                  = true
  interfaces               = ["LAN"]
  upgrade_policy           = "none"
  require_peer_certificate = false
  package_path             = ""
}

resource "routeros_wifi_security" "password" {
  name                 = "wifi-password"
  authentication_types = ["wpa2-psk", "wpa3-psk"]
  ft                   = true
  ft_preserve_vlanid   = true
  passphrase           = "test123" #!FIXME
}

resource "routeros_wifi_configuration" "slow" {
  disabled = false
  country  = "Romania"
  band     = "2ghz-ax"
  manager  = "capsman"
  mode     = "ap"
  name     = "2ghz"
  ssid     = "mickeymouse-crackhouse-2ghz"

  security = {
    config = routeros_wifi_security.password.name
  }
}

resource "routeros_wifi_configuration" "fast" {
  disabled = false
  country  = "Romania"
  band     = "5ghz-ax"
  manager  = "capsman"
  mode     = "ap"
  name     = "5ghz"
  ssid     = "mickeymouse-crackhouse-5ghz"

  security = {
    config = routeros_wifi_security.password.name
  }
}

resource "routeros_wifi_provisioning" "2ghz" {
  disabled             = false
  comment              = "2ghz configuration"
  action               = "create-dynamic-enabled"
  master_configuration = routeros_wifi_configuration.slow.name
  supported_bands      = "2ghz-ax"
}

resource "routeros_wifi_provisioning" "5ghz" {
  disabled             = false
  comment              = "5ghz configuration"
  action               = "create-dynamic-enabled"
  master_configuration = routeros_wifi_configuration.fast.name
  supported_bands      = "5ghz-ax"
}
