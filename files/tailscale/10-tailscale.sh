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

if is_in_path "tailscale" && is_service_active "tailscaled.service"; then
  export TAILSCALE_IP=$(tailscale status --json | jq -r .Self.TailscaleIPs[0])
  export TAILSCALE_SHORT_DOMAIN=$(tailscale status --json | jq -r .Self.HostName)
  export TAILSCALE_FULL_DOMAIN=$(tailscale status --json | jq -r .CertDomains[])
else
  echo "tailscale not in path or service not active"
fi
