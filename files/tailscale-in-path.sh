#! /usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

is_in_path() {
  local binary_name="$1"

  # Check if a binary name was provided
  if [[ -z "$binary_name" ]]; then
    echo "Usage: is_in_path <binary_name>" >&2
    exit 1 # Return a different error code for incorrect usage
  fi

  # Use 'command -v' which is the recommended way to check for command existence.
  # It checks aliases, functions, built-ins, and PATH lookups.
  # We redirect both stdout and stderr to /dev/null as we only care about the exit status.
  command -v "$binary_name" &> /dev/null

  # Return the exit status of 'command -v'
  # 0 means found, non-zero means not found.
  return $?
}

if is_in_path "tailscale"
then
  echo "tailscale in path"
else
  echo "tailscale NOT in path"
fi
