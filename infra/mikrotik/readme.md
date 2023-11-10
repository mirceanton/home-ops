## Getting Started

```bash
# Create a bridge interface for our WAN connection
/interface/bridge/add name=brWAN

# Enable DHCP client on the WAN bridge
/ip/dhcp-client/add disabled=no interface=brWAN

# Add the physical port to the bridge
/interface/bridge/port/add interface=ether8 bridge=brWAN

# Validate internet connectivity
ping www.google.com
```

```bash
# Create a bridge interface for our LAN connection
/interface/bridge/add name=brLAN

# Assign a static IP to it
/ip/address/add address=192.168.69.1/24 interface=brLAN

# Add the physical port to the bridge
/interface/bridge/port/add interface=ether1 bridge=brLAN
```

```bash
# Configure NAT
/ip/firewall/nat add chain=srcnat out-interface=brWAN action=masquerade
```

```bash
# Enable https api service for terraform
/certificate/add name=local-root-cert common-name=local-cert key-usage=key-cert-sign,crl-sign
/certificate/sign local-root-cert

/certificate/add name=webfig common-name=192.168.69.1
/certificate/sign webfig
/ip/service/set www-ssl certificate=webfig disabled=no
```

set static ip on pc, you should have internet

```bash
terraform import routeros_interface_bridge.wan_bridge "brWAN"
terraform import routeros_ip_dhcp_client.wan_dhcp "*1"
terraform import routeros_interface_bridge_port.wan_port "*0"
terraform import routeros_ip_firewall_nat.wan_default_nat "*2"

terraform import routeros_interface_bridge.lan_bridge "brLAN"
terraform import routeros_ip_address.lan_address "*0"
terraform import routeros_interface_bridge_port.lan_bridge_port "*1"

terraform import routeros_system_certificate.webfig_cert "*2"
```