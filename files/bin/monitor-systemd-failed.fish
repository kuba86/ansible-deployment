#!/usr/bin/env fish

# This script checks for failed systemd services every 60 seconds.
# It sends a notification only when the list of failed services has changed
# since the last check.

# --- State ---
# This variable will store the list of previously seen failed services.
set -l last_known_failed_services ""

# --- Main Loop ---
echo "Monitoring for changes in failed systemd services..."
while true
    # Get the current list of failed services and sort it for consistent comparison.
    set current_failed_services (systemctl --failed --no-legend --plain | awk '{print $1}' | sort)

    # Convert the list to a single string for easy comparison.
    set current_failed_string (string join ' ' $current_failed_services)

    # Check if the list of failed services has changed.
    if test "$current_failed_string" != "$last_known_failed_services"
        echo (date "+%Y-%m-%d %H:%M:%S") " - Change detected in failed services."

        if test -n "$current_failed_string"
            # If the new list is not empty, there are active failures.
            set message "Change in failed services on "(hostname)": "(string join ', ' $current_failed_services)
            echo "  New failed services: $message"

            # Send the notification via NTFY.
            "/home/user/.local/bin/ntfy.fish" \
                --title "FAILED services for "(hostname)"" \
                --tags "servers" \
                --topic "servers" \
                --server_url "{{ ntfy_server }}" \
                --message "$message" \
                --priority "high" \
                --apikey "{{ ntfy_api_token }}"
        else
            # If the new list is empty, it means all previous failures were resolved.
            set message "All previously failed services on "(hostname)" are now running correctly."
            echo "  All services OK."
            "/home/user/.local/bin/ntfy.fish" \
                --title "All services OK for "(hostname)"" \
                --tags "servers" \
                --topic "servers" \
                --server_url "{{ ntfy_server }}" \
                --message "$message" \
                --priority "default" \
                --apikey "{{ ntfy_api_token }}"
        end

        # Update the state to the current list of failed services.
        set last_known_failed_services "$current_failed_string"
    end

    # Wait for 60 seconds before checking again.
    sleep 60
end
