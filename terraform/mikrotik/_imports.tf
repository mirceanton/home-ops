# LAN Stuff
import {
  to = routeros_interface_bridge.home
  id = "*C"
}
import {
  to = routeros_ip_address.home
  id = "*2"
}
import {
  to = routeros_interface_bridge_port.home_switch
  id = "*1"
}
import {
  to = routeros_ip_firewall_nat.home
  id = "*1"
}


# WAN stuff
import {
  to = routeros_interface_bridge.wan
  id = "*B"
}
import {
  to = routeros_interface_bridge_port.wan_uplink
  id = "*0"
}
import {
  to = routeros_ip_dhcp_client.wan
  id = "*1"
}


# Certificates
import {
  to = routeros_system_certificate.local-root-ca-cert
  id = "*1"
}
import {
  to = routeros_system_certificate.webfig
  id = "*2"
}
