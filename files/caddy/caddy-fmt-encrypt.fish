#! /usr/bin/env fish

set -l files (fd --no-ignore --extension caddy --full-path files/caddy/etc-config) files/caddy/etc-config/Caddyfile

for file in $files
    echo "Formatting and encrypting $file"

    # format
    podman run -it --rm \
      --userns=keep-id \
      --volume=$PWD/files/caddy/etc-config:/files/caddy/etc-config:z,U \
        docker.io/library/caddy:2 caddy fmt --overwrite /$file

    # encrypt
    ansible-vault encrypt $file --output $file.encrypted
end
