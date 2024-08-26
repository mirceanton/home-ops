# Mikrotik RB5009 Terraform Automation

## Requirements

- bitwarden CLI: <https://github.com/bitwarden/clients>

## Getting Started

### Step 1. Clearing out all Default Configuration

Plug the uplink and your computer into the desired ports on the router and using WinBox, connect to the router via the MAC address and reset the device, making sure to tick the `No default configuration` box.

### Step 2. Create the minimal required configuration

First, we'll create a new bridge for our WAN connection, we'll enable a DHCP client on it and add our physical port to it.

```bash
/interface/bridge/add name=brWAN
/ip/dhcp-client/add disabled=no interface=brWAN
/interface/bridge/port/add interface=ether1 bridge=brWAN
```

After a few moments, the device should have received an IP address from the DHCP server. Test internet connectivity:

```bash
# Validate internet connectivity
ping www.google.com
```

Next, create another bridge for our LAN connection, assign an IP to it and add our physical port(s) to the bridge.

```bash
/interface/bridge/add name=brHOME
/ip/address/add address=192.168.69.1/24 interface=brHOME
/interface/bridge/port/add interface=ether7 bridge=brHOME
```

In order to get internet connectivity, we need to configure NAT:

```bash
/ip/firewall/nat add chain=srcnat out-interface=brWAN action=masquerade src-address=192.168.69.0/24
```

For terraform to be able to connecto to our router and manage it, we need to create a self signed certificate and enable the HTTPS service:

```bash
/certificate/add name=local-root-cert common-name=local-cert key-size=prime256v1 key-usage=key-cert-sign,crl-sign trusted=yes
/certificate/sign local-root-cert
/certificate/add name=webfig common-name=192.168.69.1 country=RO locality=BUC organization=MIRCEANTON unit=HOME days-valid=3650 key-size=prime256v1 key-usage=key-cert-sign,crl-sign,digital-signature,key-agreement,tls-server trusted=yes
/certificate/sign ca=local-root-cert webfig
/ip/service/set www-ssl certificate=webfig disabled=no
```

Optionally, we can now create a service account for our terraform automation as follows:

```bash
/user/add name=terraform group=full disabled=no comment="Service Account for Teraform Automation" password=terraform
```

> obviously, set a stronger password than that. this is just an example

### Step 3. Set a static IP on your workstation

### Step 4. Import previously created objects into the Terraform state

The terraform code provided has `import` blocks to handle importing all of the resources configured manuallly in [step 2](#step-2-create-the-minimal-required-configuration). Validate that all of the IDs are matching before running a `terraform apply`.

#### Importing the bridges

On Mikrotik, run the following command to print the IDs of the bridges:

```bash
:put [/interface/bridge get [print show-ids]]
```

Sample output:

```bash
*C R name="brHOME" mtu=auto actual-mtu=1500 l2mtu=1514 arp=enabled arp-timeout=auto mac-address=48:A9:8A:BD:AB:D5 protocol-mode=rstp fast-forward=yes igmp-snooping=no auto-mac=yes ageing-time=5m priority=0x8000 max-message-age=20s forward-delay=15s transmit-hold-count=6
     vlan-filtering=no dhcp-snooping=no port-cost-mode=long

*B R name="brWAN" mtu=auto actual-mtu=1500 l2mtu=1514 arp=enabled arp-timeout=auto mac-address=48:A9:8A:BD:AB:D4 protocol-mode=rstp fast-forward=yes igmp-snooping=no auto-mac=yes ageing-time=5m priority=0x8000 max-message-age=20s forward-delay=15s transmit-hold-count=6
     vlan-filtering=no dhcp-snooping=no port-cost-mode=long
```

#### Importing the DHCP Client

On Mikrotik, run the following command to print the ID of the client:

```sh
:put [/ip/dhcp-client get [print show-ids]]
```

Sample output:

```bash
Columns: INTERFACE, USE-PEER-DNS, ADD-DEFAULT-ROUTE, STATUS, ADDRESS
*  INTERFACE  USE-PEER-DNS  ADD-DEFAULT-ROUTE  STATUS  ADDRESS
*1 brWAN      yes           yes                bound   192.168.10.104/24
```

#### Importing the LAN IP address

On Mikrotik, run the following command to print the ID of the client:

```bash
:put [/ip/address get [print show-ids]]
```

Sample output:

```bash
Columns: ADDRESS, NETWORK, INTERFACE
*    ADDRESS            NETWORK       INTERFACE
*1 D 192.168.10.104/24  192.168.10.0  brWAN
*2   192.168.69.1/24    192.168.69.0  brHOME
```

#### Importing the bridge ports

On Mikrotik, run the following command to print the IDs of the bridge ports:

```bash
:put [/interface/bridge/port get [print show-ids]]
```

Sample output:

```bash
Columns: INTERFACE, BRIDGE, HW, PVID, PRIORITY, HORIZON
*    INTERFACE  BRIDGE  HW   PVID  PRIORITY  HORIZON
*0 H ether1     brWAN   yes     1  0x80      none
*1   ether2     brHOME  yes     1  0x80      none
```

#### Importing the NAT rule

On Mikrotik, run the following command to print the IDs of the NAT rules:

```bash
:put [/ip/firewall/nat get [print show-ids]]
```

Sample output:

```bash
*1    chain=srcnat action=masquerade src-address=192.168.69.0/24 out-interface=brWAN
```

#### Importing the self signed certificate

On Mikrotik, run the following command to print the IDs of the system certificates:

```bash
:put [/certificate get [print show-ids]]
```

```bash
Columns: NAME, COMMON-NAME, SKID
*      NAME             COMMON-NAME   SKID
*1 KAT local-root-cert  local-cert    a0c40660c79d2753c110147136272dce6d24b513
*2 KAT webfig           192.168.69.1  d8ff3c5980cc520454ed8d39385ff586e396b563
```
