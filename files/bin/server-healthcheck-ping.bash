#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

random-delay-seconds.bash 0 1

# List of hosts to ping
HOSTS=(
{{ server_healthcheck_ping }}
)

# Array to store failed pings
FAILED_PINGS=()

# Function to ping a host and check if it fails
ping_host() {
    local host=$1
    local max_retries=5
    local attempt=1

    echo "Pinging $host..."

    while [ $attempt -le $max_retries ]; do
        echo "  Attempt $attempt for $host..."
        
        # Execute the podman ping command
        # Note: We need to handle the command failure explicitly due to set -e
        if podman run -it --rm --cap-add=NET_RAW fedora-dev:latest ping -c 4 -q -i 0.1 "$host" >/dev/null 2>&1; then
            echo "SUCCESS: $host (succeeded on attempt $attempt)"
            return 0
        else
            echo "  Failed attempt $attempt for $host"
            if [ $attempt -lt $max_retries ]; then
                echo "  Retrying in 5 seconds..."
                sleep 5
            fi
        fi
        
        ((attempt++))
    done
    
    # If we reach here, all attempts failed
    echo "FAILED: $host (all $max_retries attempts failed)"
    FAILED_PINGS+=("$host")
}

# Function to send notification via ntfy.fish
send_notification() {
    local message=$1
    local ntfy_command="$HOME/ntfy.fish"
    if command -v "$ntfy_command" >/dev/null 2>&1; then
        "$ntfy_command" \
        --title "Server healthcheck FAILED" \
        --tags "servers,healthcheck" \
        --topic "servers" \
        --server_url "{{ ntfy_server }}" \
        --message "$message" \
        --priority "high" \
        --apikey "{{ ntfy_api_token }}"
    else
        echo "ntfy.fish not found. Failed pings message:"
        echo "$message"
    fi
}

# Main execution
main() {
    echo "Starting ping tests..."
    echo "========================"

    # Ping each host
    for host in "${HOSTS[@]}"; do
        ping_host "$host"
    done

    echo "========================"
    echo "Ping tests completed."

    # Check if there are any failed pings
    if [ ${#FAILED_PINGS[@]} -eq 0 ]; then
        echo "All pings succeeded!"
    else
        echo "Failed pings detected: ${#FAILED_PINGS[@]} host(s)"

        # Create the message string
        local failed_list=""
        for failed_host in "${FAILED_PINGS[@]}"; do
            if [ -z "$failed_list" ]; then
                failed_list="$failed_host"
            else
                failed_list="$failed_list, $failed_host"
            fi
        done

        local notification_message="Ping failures detected for the following hosts: $failed_list"
        echo "Sending notification: $notification_message"
        send_notification "$notification_message"
        exit 1
    fi
}

# Run the main function
main
