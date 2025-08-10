#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

random-delay-seconds.bash 0 1

# List of websites to check
WEBSITES=(
{{ server_healthcheck_website }}
)

# Array to store failed website checks
FAILED_CHECKS=()

# Function to check a website and verify if it returns 2xx status code
check_website() {
    local website=$1
    local max_retries=3
    local attempt=1

    echo "Checking $website..."

    while [ $attempt -le $max_retries ]; do
        echo "  Attempt $attempt for $website..."
        
        # Execute curl command to check HTTP status code
        # Note: We need to handle the command failure explicitly due to set -e
        local http_code
        if http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$website" 2>/dev/null) && [[ $http_code =~ ^2[0-9][0-9]$ ]]; then
            echo "SUCCESS: $website (HTTP $http_code, succeeded on attempt $attempt)"
            return 0
        else
            echo "  Failed attempt $attempt for $website (HTTP ${http_code:-"no response"})"
            if [ $attempt -lt $max_retries ]; then
                echo "  Retrying in 5 seconds..."
                sleep 5
            fi
        fi
        
        ((attempt++))
    done
    
    # If we reach here, all attempts failed
    echo "FAILED: $website (all $max_retries attempts failed, last HTTP code: ${http_code:-"no response"})"
    FAILED_CHECKS+=("$website")
}

# Function to send notification via ntfy.fish
send_notification() {
    local message=$1
    local ntfy_command="$HOME/ntfy.fish"
    if command -v "$ntfy_command" >/dev/null 2>&1; then
        "$ntfy_command" \
        --title "website healthcheck FAILED" \
        --tags "website,healthcheck" \
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
    echo "Starting website checks..."
    echo "========================"

    # Check each website
    for website in "${WEBSITES[@]}"; do
        check_website "$website"
    done

    echo "========================"
    echo "Website checks completed."

    # Check if there are any failed checks
    if [ ${#FAILED_CHECKS[@]} -eq 0 ]; then
        echo "All website checks succeeded!"
    else
        echo "Failed website checks detected: ${#FAILED_CHECKS[@]} website(s)"

        # Create the message string
        local failed_list=""
        for failed_website in "${FAILED_CHECKS[@]}"; do
            if [ -z "$failed_list" ]; then
                failed_list="$failed_website"
            else
                failed_list="$failed_list, $failed_website"
            fi
        done

        local notification_message="Website check failures detected for the following websites: $failed_list"
        echo "Sending notification: $notification_message"
        send_notification "$notification_message"
    fi
}

# Run the main function
main
