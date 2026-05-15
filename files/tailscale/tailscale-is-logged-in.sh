#! /usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

check_command_output() {
  local expected_output="$1"
  shift

  # Check if both arguments were provided
  # Note: An empty expected string is allowed, but the command must be passed.
  if [[ $# -lt 1 ]]; then
    echo "Usage: check_command_output <expected_output_string> <command> [args...]" >&2
    echo "Example: check_command_output 'hello' echo hello" >&2
    return 1
  fi

  # --- Execute the command and capture its standard output ---
  # We capture only stdout. stderr is ignored (redirected to /dev/null).
  local actual_output
  actual_output=$("$@" 2>/dev/null)
  local command_exit_status=$? # Optional: capture the command's exit status

  # Optional: Check if the command executed successfully (exit status 0)
  # You might want to return a different error code if the command itself failed.
  if [[ $command_exit_status -ne 0 ]]; then
    # echo "Warning: Command failed with exit status $command_exit_status. The command: '$*'" >&2
    : # Do nothing, this is often expected
  fi

  # --- Compare the captured output with the expected string ---
  # Use [[ ... ]] for safer string comparisons. Quote variables.
  # Note: Command substitution $(...) often removes trailing newlines.
  # If your expected output includes a trailing newline, this comparison might
  # require adjustment (e.g., compare "$actual_output"$'\n' == "$expected_output").
  if [[ "$actual_output" == "$expected_output" ]]; then
    return 0 # Success: Output matches
  else
    # Optional: Print details on mismatch for debugging
    # echo "Mismatch Expected vs Actual" >&2
    # echo "Expected: '$expected_output'" >&2
    # echo "Actual:   '$actual_output'" >&2
    return 1 # Failure: Output does not match
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if check_command_output "failed to connect to local tailscaled; it doesn't appear to be running (sudo systemctl start tailscaled ?)" tailscale status --peers=false
  then
    echo "tailscale is not running"
  elif check_command_output "faile" tailscale status --peers=false
  then
    echo ""
  else
    echo ""
  fi
fi
