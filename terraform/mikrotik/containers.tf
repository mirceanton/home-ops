## ================================================================================================
## Container System Configuration
## ================================================================================================
resource "routeros_container_config" "config" {
  registry_url = "https://registry-1.docker.io"
  ram_high     = "0"
  tmpdir       = "/usb1-part1/containers/tmp"
  layer_dir    = "/usb1-part1/containers/layers"
}


## ================================================================================================
## Bridge Network Configuration
## ================================================================================================
resource "routeros_interface_bridge" "containers" {
  name = "brCONTAINERS"
}
resource "routeros_ip_address" "containers" {
  address   = "172.19.0.1/24"
  interface = routeros_interface_bridge.containers.name
  network   = "172.19.0.0"
}

resource "routeros_ip_firewall_nat" "containers" {
  comment       = "NAT Containers Traffic"
  chain         = "srcnat"
  out_interface = routeros_interface_bridge.wan.name
  action        = "masquerade"
  src_address   = "${routeros_ip_address.containers.network}/24"
}


## ================================================================================================
## Cloudflare DDNS
## ================================================================================================
resource "routeros_interface_veth" "cloudflare-ddns" {
  name    = "veth-cloudflare-ddns"
  address = "172.19.0.2/24"
  gateway = "172.19.0.1"
  comment = "cloudflare-ddns Virtual interface"
}
resource "routeros_interface_bridge_port" "cloudflare-ddns" {
  bridge    = routeros_interface_bridge.containers.name
  interface = routeros_interface_veth.cloudflare-ddns.name
  comment   = routeros_interface_veth.cloudflare-ddns.comment
  pvid      = "1"
}

resource "routeros_container_envs" "cloudflare-ddns-token" {
  name  = "cloudflare-ddns-envs"
  key   = "CF_API_TOKEN"
  value = var.cloudflare_token
}
resource "routeros_container_envs" "cloudflare-ddns-domains" {
  name  = "cloudflare-ddns-envs"
  key   = "DOMAINS"
  value = "vpn.${local.external_domain}"
}
resource "routeros_container_envs" "cloudflare-ddns-timezone" {
  name  = "cloudflare-ddns-envs"
  key   = "TZ"
  value = routeros_system_clock.timezone.time_zone_name
}
resource "routeros_container" "cloudflare-ddns" {
  comment      = "Cloudflare DDNS"
  remote_image = "favonia/cloudflare-ddns:1.13.2"

  interface     = routeros_interface_veth.cloudflare-ddns.name
  logging       = true
  start_on_boot = true

  envlist = "cloudflare-ddns-envs"
}


## ================================================================================================
## Cloudflare DDNS Status Notification
## ================================================================================================
resource "routeros_system_script" "check_cloudflare_ddns" {
  name    = "check-cloudflare-ddns"
  comment = "Send Discord notification on Cloudflare DDNS container state change"
  policy  = ["read"]
  source  = <<-EOF
    :local containerName "${routeros_container.cloudflare-ddns.name}"
    :local webhookUrl "${var.discord_webhook_url}";

    # Get the current state of the container
    :local currentState [/container get [find name=\$containerName] status]

    # Global variable to store the previous state
    :global previousState

    # If the previous state does not exist (is empty), initialize it to the current status
    :if ([:len \$previousState] = 0) do={
        :set previousState \$currentState
    }

    # Check for state change
    :if (\$currentState != \$previousState) do={
        # Prepare Discord notification
        :local message "Cloudflare DDNS Container State Change from \$previousState to \$currentState"

        # Send the notification to Discord
        /tool fetch url=($webhookUrl) http-method=post http-data=("content=" . $message) mode=https keep-result=no

        # Update the previous state
        :set previousState \$currentState
    }
  EOF
}
resource "routeros_scheduler" "check_ddns_container" {
  name     = "check-cloudflare-ddns-container"
  comment  = "Check the Cloudflare DDNS container state every 5 minutes"
  interval = "5s"
  on_event = routeros_system_script.check_cloudflare_ddns.name
}
