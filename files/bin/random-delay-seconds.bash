#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 min max"
    exit 1
fi

# Assign arguments to variables
min=$1
max=$2

# Validate that min and max are positive integers
if ! [[ "$min" =~ ^[0-9]+$ ]] || ! [[ "$max" =~ ^[0-9]+$ ]]; then
    echo "Error: min and max must be positive integers."
    exit 1
fi

if [ "$min" -ge "$max" ]; then
    echo "Error: min must be less than max."
    exit 1
fi

# Convert minutes to seconds
min_seconds=$((min * 60))
max_seconds=$((max * 60))

# Generate a random number of seconds between min_seconds and max_seconds
random_seconds=$((RANDOM % (max_seconds - min_seconds + 1) + min_seconds))

# Print the delay
echo "Delay: $random_seconds seconds"

# Optionally, you can add a sleep command to actually delay the script
sleep $random_seconds
