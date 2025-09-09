#! /usr/bin/env bash

set -euo pipefail

export domains="{{ lets_encrypt_domains }}"
export lets_encrypt_path="{{ lets_encrypt_path }}"
export caddy_path="{{ caddy_path }}"

read -ra domain_array <<< "$domains"

counter=0

function check_certs() {
  for domain in "${domain_array[@]}"; do
    local source_crt="$lets_encrypt_path/.lego/certificates/$domain.crt"
    local dest_crt="$caddy_path/tls/live/$domain.crt"

    local source_key="$lets_encrypt_path/.lego/certificates/$domain.key"
    local dest_key="$caddy_path/tls/live/$domain.key"

    # Ensure source files exist before trying to compare
    if [[ ! -f "$source_crt" || ! -f "$source_key" ]]; then
      echo "ERROR: Source certificate or key for $domain not found. Skipping."
      continue
    fi

    if ! cmp --silent "$source_crt" "$dest_crt" || ! cmp --silent "$source_key" "$dest_key"; then
      echo "Cert or key for $domain has changed. Incrementing counter."
      ((counter++))
    fi
  done
}

function copy_certs() {
  for domain in "${domain_array[@]}"; do
    echo "------ $domain -------"
    cp "$lets_encrypt_path/.lego/certificates/$domain.crt" "$caddy_path/tls/live/$domain.crt"
    cp "$lets_encrypt_path/.lego/certificates/$domain.key" "$caddy_path/tls/live/$domain.key"
  done
}

check_certs

if [ $counter -gt 0 ]; then
  ntfy.fish \
    --title "Lets Encrypt | Caddy setup certs" \
    --tags "lets-encrypt" \
    --topic "servers" \
    --server_url "{{ ntfy_server }}" \
    --message "Starting to copy Lets Encrypt certificates and restarting Caddy" \
    --priority "high" \
    --apikey "{{ ntfy_api_token }}"

  copy_certs

  echo "------ Restarting Caddy Server -------"
  podman exec caddy caddy reload --force --config /etc/caddy/Caddyfile
else
  echo "No certs changed"
fi
