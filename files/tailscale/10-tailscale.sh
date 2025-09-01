is_in_path() {
  local binary_name="$1"
  command -v "$binary_name" &> /dev/null
  return $?
}

is_service_active() {
  local service_name="$1"
  systemctl is-active --quiet "$service_name"
  return $?
}

is_tailscale_ip_null() {
  local tailscale_ip=$(tailscale status --json | jq -r .Self.TailscaleIPs[0])
  [[ "$tailscale_ip" == "null" ]]
  return $?
}

if ! is_in_path "tailscale"; then
  echo "tailscale not in path"
elif ! is_service_active "tailscaled.service"; then
  echo "tailscaled.service not active"
elif is_tailscale_ip_null; then
  echo "Tailscale IP is null - device may not be connected to the tailnet"
else
  export TAILSCALE_IP=$(tailscale status --json | jq -r .Self.TailscaleIPs[0])
  export TAILSCALE_SHORT_DOMAIN=$(tailscale status --json | jq -r .Self.HostName)
  export TAILSCALE_FULL_DOMAIN=$(tailscale status --json | jq -r .CertDomains[])
fi
