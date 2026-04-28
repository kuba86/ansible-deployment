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

if ! is_in_path "tailscale"; then
  echo "tailscale not in path"
elif ! is_service_active "tailscaled.service"; then
  echo "tailscaled.service not active"
else
  tailscale_status=$(tailscale status --json)
  tailscale_ip=$(echo "$tailscale_status" | jq -r .Self.TailscaleIPs[0])
  if [[ "$tailscale_ip" == "null" ]]; then
    echo "Tailscale IP is null - device may not be connected to the tailnet"
  else
    export TAILSCALE_IP="$tailscale_ip"
    export TAILSCALE_SHORT_DOMAIN=$(echo "$tailscale_status" | jq -r .Self.HostName)
    export TAILSCALE_FULL_DOMAIN=$(echo "$tailscale_status" | jq -r .CertDomains[])
  fi
  unset tailscale_status
  unset tailscale_ip
fi
