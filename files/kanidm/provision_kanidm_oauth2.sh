#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  provision_kanidm_oauth2.sh <client_id> <display_name> <group_name> <domain> "<scopes...>"

Example:
  provision_kanidm_oauth2.sh oauth2-proxy-xyz "oauth2-proxy-xyz" xyz_users xyz.example.com "openid email profile"
EOF
}

if [[ $# -lt 5 ]]; then
  usage
  exit 2
fi

client_id="$1"
display_name="$2"
group_name="$3"
domain="$4"
scopes_str="$5"

if ! command -v kanidm >/dev/null 2>&1; then
  echo "ERROR: 'kanidm' command not found." >&2
  exit 1
fi

# Split scopes string into array args
read -r -a scopes_arr <<<"$scopes_str"

# Create group (ignore error if it already exists)
kanidm group create "$group_name" >/dev/null 2>&1 || true

kanidm system oauth2 create "$client_id" "$display_name" "https://$domain"
kanidm system oauth2 add-redirect-url "$client_id" "https://$domain/oauth2/callback"

# Use group_name (as documented)
kanidm system oauth2 update-scope-map "$client_id" "$group_name" "${scopes_arr[@]}"
# Example in docs: kanidm system oauth2 update-scope-map nextcloud nextcloud_users email profile openid [web:18]

secret_out="$(kanidm system oauth2 show-basic-secret "$client_id")"

# Extract secret. Common output format is:
# ---
# <secret>
client_secret=""
seen_sep=0
while IFS= read -r line; do
  if [[ "$line" == "---" ]]; then
    seen_sep=1
    continue
  fi
  if [[ "$seen_sep" -eq 1 && -n "$line" ]]; then
    client_secret="$line"
    break
  fi
done <<<"$secret_out"

# Fallback: last non-empty line
if [[ -z "${client_secret:-}" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && client_secret="$line"
  done <<<"$secret_out"
fi

if [[ -z "${client_secret:-}" ]]; then
  echo "ERROR: Could not parse client secret from show-basic-secret output" >&2
  echo "$secret_out" >&2
  exit 1
fi

cookie_secret="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 || true)"

echo ""
echo "cookie_domain: $domain"
echo "client_id: $client_id"
echo "client_secret: $client_secret"
echo "cookie_secret: $cookie_secret"
