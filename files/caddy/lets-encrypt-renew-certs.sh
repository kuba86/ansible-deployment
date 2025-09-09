#! /usr/bin/env bash

set -euo pipefail

export lego_version="latest"
export email="{{ lets_encrypt_email }}"
export cf_dns_api_token="{{ cf_dns_api_token }}"
export cf_polling_interval="30"
export cf_propagation_timeout="130"
export cf_ttl="120"
export domains="{{ lets_encrypt_domains }}"
export lets_encrypt_path="{{ lets_encrypt_path }}"
export dns_servers="1.1.1.1:53,1.0.0.1:53"

function renew() {
  read -ra domain_array <<< "$domains"

  for domain in "${domain_array[@]}"; do
    echo "------ $domain -------" >&2
    podman run --rm \
      --name=letsencrypt \
      --volume="$lets_encrypt_path/.lego:/.lego:z" \
      --env=CF_DNS_API_TOKEN="$cf_dns_api_token" \
      --env=CLOUDFLARE_POLLING_INTERVAL="$cf_polling_interval" \
      --env=CLOUDFLARE_PROPAGATION_TIMEOUT="$cf_propagation_timeout" \
      --env=CLOUDFLARE_TTL="$cf_ttl" \
      docker.io/goacme/lego:"$lego_version" \
        --accept-tos \
        --dns.resolvers="$dns_servers" \
        --email="$email" \
        --dns=cloudflare \
        --domains="$domain" \
        --domains="*.$domain" \
        renew --no-random-sleep
  done
}

renew
