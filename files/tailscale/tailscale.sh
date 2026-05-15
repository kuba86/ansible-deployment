#! /usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

is_in_path() {
  local binary_name="$1"

  # Check if a binary name was provided
  if [[ -z "$binary_name" ]]; then
    echo "Usage: is_in_path <binary_name>" >&2
    return 2 # Return a different error code for incorrect usage
  fi

  # Use 'command -v' which is the recommended way to check for command existence.
  # It checks aliases, functions, built-ins, and PATH lookups.
  # We redirect both stdout and stderr to /dev/null as we only care about the exit status.
  command -v "$binary_name" &> /dev/null

  # Return the exit status of 'command -v'
  # 0 means found, non-zero means not found.
  return $?
}


check_command_output() {
  local expected_output="$1"
  shift

  # Check if both arguments were provided
  # Note: An empty expected string is allowed, but the command must be passed.
  if [[ $# -lt 1 ]]; then
    echo "Usage: check_command_output <expected_output_string> <command> [args...]" >&2
    echo "Example: check_command_output 'hello' echo hello" >&2
    return 2
  fi

  # --- Execute the command and capture its standard output ---
  # We capture only stdout. stderr is ignored (redirected to /dev/null).
  local actual_output
  actual_output=$("$@" 2>/dev/null)
  local command_exit_status=$? # Optional: capture the command's exit status

  # Optional: Check if the command executed successfully (exit status 0)
  # You might want to return a different error code if the command itself failed.
  if [[ $command_exit_status -ne 0 ]]; then
    # echo "Warning: Command '$*' failed with exit status $command_exit_status." >&2
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
    echo "Mismatch Details:" >&2
    echo "Expected: '$expected_output'" >&2
    echo "Actual:   '$actual_output'" >&2
    return 1 # Failure: Output does not match
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if is_in_path "tailscale"
  then
    echo "tailscale in path"
  else
    echo "tailscale NOT in path"
  fi

  if check_command_output "failed to connect to local tailscaled; it doesn't appear to be running (sudo systemctl start tailscaled ?)" tailscale status
  then
    echo "failed to connect to local tailscaled"
  else
    echo "connected to tailscaled"
  fi
fi
