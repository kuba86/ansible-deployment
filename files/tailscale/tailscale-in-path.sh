#! /usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

is_in_path() {
  local binary_name="$1"

  if [[ -z "$binary_name" ]]; then
    echo "Usage: is_in_path <binary_name>" >&2
    exit 1
  fi

  command -v "$binary_name" &> /dev/null
  return $?
}

if is_in_path "tailscale"
then
  echo "tailscale in path"
else
  echo "tailscale NOT in path"
fi
