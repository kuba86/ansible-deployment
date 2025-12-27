#!/usr/bin/env fish

set -g cert_files_path "$LEGO_PATH/certificates"

function restic-restore
    echo ">>> [1/4] Restoring latest data from Restic..."
    # Note: Using LEGO_PATH to ensure we restore to the exact location Lego expects
    if restic restore "latest:$LEGO_PATH" --target /
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
    echo ">>> [3/4] New certificate generated. Syncing to Garage via Rclone..."

    create_rclone_conf

    if rclone copy "$cert_files_path" garage:lets-encrypt/certs --include "$main_domain.{crt,key}"
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

# 1. Restore from Restic
restic-restore

# Prepare Lego flags (Global so functions can access them)
set -g lego_domain_flags
for domain in (string split " " $domains)
    set --append lego_domain_flags --domains="$domain" --domains="*.$domain"
end

# 2. Run Lego
# We capture the output to keep the main loop clean and display it after execution
set -l lego_output
set -l lego_status

if test "$lego_mode" = "renew"
    set lego_output (lego-renew)
    set lego_status $status
else if test "$lego_mode" = "run"
    set lego_output (lego-run)
    set lego_status $status
else
    echo ">>> Error: lego_mode variable must be set to 'renew' or 'run'. Got: '$lego_mode'"
    exit 1
end

echo $lego_output

if test $lego_status -eq 0
    echo ">>> Lego command finished successfully."

    # 3. Check if renewal actually occurred and sync with Rclone
    # We check file timestamps to determine if a new certificate was actually written.
        
    # Note: Adjust the filename pattern if your certs are named differently
    set -l cert_file "$cert_files_path/$main_domain.crt"

    # Check if cert file exists and was modified in the last 5 minutes (approx duration of script)
    if test -f "$cert_file"; and test (find "$cert_file" -mmin -5)
        rclone-copy-certs
    else
        echo ">>> [3/4] No new certificate generated (likely not due for renewal). Skipping Rclone sync."
    end

    # 4. Backup new state to Restic
    restic-backup

else
    echo ">>> Error: Lego renewal failed."
    exit 1
end

echo ">>> Workflow completed."
