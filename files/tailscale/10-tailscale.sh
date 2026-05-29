case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

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
  tailscale_status="$(tailscale status --json 2>/dev/null || true)"
  tailscale_ip="$(printf '%s' "$tailscale_status" | jq -r '.Self.TailscaleIPs[0] // empty' 2>/dev/null)"

  if [[ -n "$tailscale_ip" ]]; then
    tailscale_short_domain="$(printf '%s' "$tailscale_status" | jq -r '.Self.HostName // empty' 2>/dev/null)"
    tailscale_full_domain="$(printf '%s' "$tailscale_status" | jq -r '.CertDomains[]?' 2>/dev/null)"

    export TAILSCALE_IP="$tailscale_ip"
    export TAILSCALE_SHORT_DOMAIN="$tailscale_short_domain"
    export TAILSCALE_FULL_DOMAIN="$tailscale_full_domain"
  fi

  unset tailscale_status
  unset tailscale_ip
  unset tailscale_short_domain
  unset tailscale_full_domain
fi
