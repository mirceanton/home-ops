# Mikrotik RB5009 Automation

## Getting Started

### Step 1. Clearing out all Default Configuration

Plug the uplink and your computer into the desired ports on the router and using WinBox, connect to the router via the MAC address and reset the device, making sure to tick the `No default configuration` box.

### Step 2. Create the minimal required configuration

First, we'll create a new bridge for our WAN connection, we'll enable a DHCP client on it and add our physical port to it.

```bash
/interface/bridge/add name=brWAN
/ip/dhcp-client/add disabled=no interface=brWAN
/interface/bridge/port/add interface=ether8 bridge=brWAN
```

After a few moments, the device should have received an IP address from the DHCP server. Test internet connectivity:

```bash
# Validate internet connectivity
ping www.google.com
```

Next, create another bridge for our LAN connection, assign an IP to it and add our physical port(s) to the bridge.

```bash
/interface/bridge/add name=brLAN
/ip/address/add address=192.168.69.1/24 interface=brLAN
/interface/bridge/port/add interface=ether1 bridge=brLAN
```

In order to get internet connectivity, we need to configure NAT:

```bash
/ip/firewall/nat add chain=srcnat out-interface=brWAN action=masquerade
```

For terraform to be able to connecto to our router and manage it, we need to create a self signed certificate and enable the HTTPS service:

```bash
/certificate/add name=local-root-cert common-name=local-cert key-usage=key-cert-sign,crl-sign
/certificate/sign local-root-cert
/certificate/add name=webfig common-name=192.168.69.1
/certificate/sign webfig
/ip/service/set www-ssl certificate=webfig disabled=no
```

### Step 3. Set a static IP on your workstation

### Step 4. Import previously created objects into the Terraform state

#### Importing the bridges

On Mikrotik, run the following command to print the IDs of the bridges:

```bash
[admin@MikroTik] > :put [/interface/bridge get [print show-ids]]
Flags: X - disabled, R - running 
*B R name="brLAN" mtu=auto actual-mtu=1500 l2mtu=1514 arp=enabled arp-timeout=auto mac-address=48:A9:8A:BD:AB:D4 protocol-mode=rstp fast-forward=yes igmp-snooping=no auto-mac=yes ageing-time=5m priority=0x8000 max-message-age=20s forward-delay=15s 
     transmit-hold-count=6 vlan-filtering=no dhcp-snooping=no 

*A R name="brWAN" mtu=auto actual-mtu=1500 l2mtu=1514 arp=enabled arp-timeout=auto mac-address=48:A9:8A:BD:AB:DB protocol-mode=rstp fast-forward=yes igmp-snooping=no auto-mac=yes ageing-time=5m priority=0x8000 max-message-age=20s forward-delay=15s 
     transmit-hold-count=6 vlan-filtering=no dhcp-snooping=no 
```

Based on the example output, the ID of our WAN bridge is `*A` and the ID of our LAN bridge is `*B`:

```bash
terraform import routeros_interface_bridge.wan_bridge "*A"
terraform import routeros_interface_bridge.lan_bridge "*B"
```

#### Importing the DHCP Client

On Mikrotik, run the following command to print the ID of the client:

```bash
[admin@MikroTik] > :put [/ip/dhcp-client get [print show-ids]]
Columns: INTERFACE, USE-PEER-DNS, ADD-DEFAULT-ROUTE, STATUS, ADDRESS
*  INTERFACE  USE-PEER-DNS  ADD-DEFAULT-ROUTE  STATUS  ADDRESS
*1 brWAN      yes           yes                bound   192.168.10.170/24
```

Based on the example output, the ID of our dhcp client on the WAN interface is `*1`:

```bash
terraform import routeros_ip_dhcp_client.wan_dhcp "*1"
```

#### Importing the LAN IP address

On Mikrotik, run the following command to print the ID of the client:

```bash
[admin@MikroTik] > :put [/ip/address get [print show-ids]]
Flags: D - DYNAMIC
Columns: ADDRESS, NETWORK, INTERFACE
*    ADDRESS            NETWORK       INTERFACE
*1 D 192.168.10.170/24  192.168.10.0  brWAN
*2   192.168.69.1/24    192.168.69.0  brLAN
```

Based on the example output, the ID of our LAN IP address is `*2`:

```bash
terraform import routeros_ip_address.lan_address "*2"
```

#### Importing the bridge ports:

On Mikrotik, run the following command to print the IDs of the bridge ports:

```bash
[admin@MikroTik] > :put [/interface/bridge/port get [print show-ids]]
Flags: H - HW-OFFLOAD
Columns: INTERFACE, BRIDGE, HW, PVID, PRIORITY, PATH-COST, INTERNAL-PATH-COST, HORIZON
*    INTERFACE  BRIDGE  HW   PVID  PRIORITY  PATH-COST  INTERNAL-PATH-COST  HORIZON
*0 H ether8     brWAN   yes     1  0x80             10                  10  none   
*1   ether1     brLAN   yes     1  0x80             10                  10  none  
```

Based on the example output, the ID of our LAN bridge port is `*1` and for our WAN bridge port we have `*0`:

```bash
terraform import routeros_interface_bridge_port.wan_bridge_port "*0"
terraform import routeros_interface_bridge_port.lan_bridge_port "*1"
```

#### Importing the NAT rule

On Mikrotik, run the following command to print the IDs of the NAT rules:

```bash
[admin@MikroTik] > :put [/ip/firewall/nat get [print show-ids]]
Flags: X - disabled, I - invalid; D - dynamic 
*1    chain=srcnat action=masquerade out-interface=brWAN 
```

Based on the example output, the ID of our NAT rule is `*1`:

```bash
terraform import routeros_ip_firewall_nat.wan_default_nat "*1"
```

#### Importing the self signed certificate

On Mikrotik, run the following command to print the IDs of the system certificates:

```bash
[admin@MikroTik] > :put [/certificate get [print show-ids]]
Flags: K - PRIVATE-KEY; A - AUTHORITY; E - EXPIRED; T - TRUSTED
Columns: NAME, COMMON-NAME, SKID
*       NAME             COMMON-NAME   SKID
*1 KAET local-root-cert  local-cert    2d6cf098d1c69e03ba835fceadfcf05f5200c562
*3 KAET webfig           192.168.69.1  d05bb506bf7c31b4d0ba235b23d2871a6e72ce74
```

Based on the example output, the ID of our webfig certificate is `*3`:

```bash
terraform import routeros_system_certificate.webfig_cert "*3"
```
