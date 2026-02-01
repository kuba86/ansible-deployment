#!/usr/bin/env fish

set -g cert_files_path "$LEGO_PATH/certificates"

function parse-args
    # Prefer CLI flags but fall back to environment variables for backward compatibility
    argparse --name "lets-encrypt" 'renew' 'run' 'domains=' 'file-name=' -- $argv
    or exit 1

    if set -q _flag_renew; and set -q _flag_run
        echo ">>> Error: choose either --renew or --run, not both."
        exit 1
    end

    if set -q _flag_renew
        set -g lego_mode "renew"
    else if set -q _flag_run
        set -g lego_mode "run"
    end

    if set -q _flag_domains
        set -g domains $_flag_domains
    end

    if set -q _flag_file_name
        set -g file_name $_flag_file_name
    end

    # Backward compatibility: allow existing env var main_domain
    if not set -q file_name; and set -q main_domain
        set -g file_name $main_domain
    end

    if not set -q lego_mode
        echo ">>> Error: lego_mode not set. Use --renew or --run (or set the lego_mode env var)."
        exit 1
    end

    if not set -q domains
        echo ">>> Error: domains not provided. Use --domains or set the domains env var."
        exit 1
    end

    if not set -q file_name
        echo ">>> Error: certificate file name not provided. Use --file-name or set the file_name env var (main_domain is also accepted for compatibility)."
        exit 1
    end
end

function restic-restore
    echo ">>> [1/4] Restoring latest data from Restic..."
    # Note: Using LEGO_PATH to ensure we restore to the exact location Lego expects
    if restic restore "latest:$LEGO_PATH" --target $LEGO_PATH
        echo ">>> Restic restore successful."
    else
        echo ">>> Error: Restic restore failed. Exiting."
        exit 1
    end
end

function lego-renew
    echo ">>> [2/4] Attempting to renew certificates with Lego..." >&2
    lego \
        --accept-tos \
        --dns.resolvers="$dns_servers" \
        --dns="cloudflare" \
        --path="$LEGO_PATH" \
        $lego_domain_flags \
        renew --no-random-sleep 2>&1
end

function lego-run
    echo ">>> [2/4] Attempting to obtain certificates with Lego..." >&2
    lego \
        --accept-tos \
        --dns.resolvers="$dns_servers" \
        --dns="cloudflare" \
        --path="$LEGO_PATH" \
        $lego_domain_flags \
        run 2>&1
end

function create_rclone_conf
    mkdir -p /root/.config/rclone
    echo "[garage]
type = s3
provider = Other
access_key_id = $AWS_ACCESS_KEY_ID
secret_access_key = $AWS_SECRET_ACCESS_KEY
region = us-east-1
endpoint = http://host.containers.internal:53901" > /root/.config/rclone/rclone.conf
end

function rclone-copy-certs
    echo ">>> [3/4] Syncing certificates to Garage via Rclone..."

    create_rclone_conf

    if rclone copy "$cert_files_path" garage:lets-encrypt/certs --include "$file_name.{crt,key}" --verbose
        echo ">>> Rclone sync successful."
    else
        echo ">>> Error: Rclone sync failed."
        # We don't exit here, we still want to backup the new state
    end
end

function restic-backup
    echo ">>> [4/4] Backing up current state to Restic..."
    if restic backup "$LEGO_PATH"
        echo ">>> Restic backup successful."
    else
        echo ">>> Error: Restic backup failed."
        exit 1
    end
end

# --- Main Execution ---

parse-args $argv

# Normalize domain list and prepare Lego flags (Global so functions can access them)
set -l normalized_domains
for raw in $domains
    for domain in (string split " " -- $raw)
        if test -n "$domain"
            set --append normalized_domains $domain
        end
    end
end

if test (count $normalized_domains) -eq 0
    echo ">>> Error: No domains provided after parsing."
    exit 1
end

set -g domains $normalized_domains
set -g lego_domain_flags
for domain in $domains
    set --append lego_domain_flags --domains="$domain"
end

# 1. Restore from Restic
restic-restore

# 2. Run Lego
# We capture the output to keep the main loop clean and display it after execution
set -l lego_output
set -l lego_status

if test "$lego_mode" = "renew"
    # Capture output and status in one list: [output_string, status_code]
    set -l result (lego-renew | string collect; echo $pipestatus[1])
    set lego_output $result[1..-2]
    set lego_status $result[-1]
else if test "$lego_mode" = "run"
    set -l result (lego-run | string collect; echo $pipestatus[1])
    set lego_output $result[1..-2]
    set lego_status $result[-1]
else
    echo ">>> Error: lego_mode variable must be set to 'renew' or 'run'. Got: '$lego_mode'"
    exit 1
end

echo "$lego_output"

if test $lego_status -eq 0
    echo ">>> Lego command finished successfully."

    # 3. Always sync certs after Lego finishes
    rclone-copy-certs

    # 4. Backup new state to Restic
    restic-backup

else
    echo ">>> Error: Lego renewal failed."
    exit 1
end

echo ">>> Workflow completed."
