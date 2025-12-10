set -l lets_encrypt_path "{{ lets_encrypt_path }}"
set -l caddy_path "{{ caddy_path }}"
set -l ntfy_script "ntfy.fish"
set -l sync_output (rsync -ai --include '*/' --include '*.crt' --include '*.key' --exclude '*' --prune-empty-dirs "$lets_encrypt_path/.lego/certificates/" "$caddy_path/tls/live/")

if test -n "$sync_output"
    echo "Changes detected. Files copied:"
    echo "$sync_output"

    if test -x "$ntfy_script"
        echo "Triggering notification..."
        ntfy.fish \
            --title "Lets Encrypt | Caddy setup certs" \
            --tags "lets-encrypt" \
            --topic "servers" \
            --server_url "{{ ntfy_server }}" \
            --message "Files copied: $sync_output" \
            --priority "high" \
            --apikey "{{ ntfy_api_token }}"

        echo "Restarting Caddy Server..."
        podman exec caddy caddy reload --force --config /etc/caddy/Caddyfile
    else
        echo "Error: $ntfy_script not found or not executable."
        exit 1
    end
else
    echo "No new or changed certificates found."
    exit 0
end
