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
  local command_to_run="$1"
  local expected_output="$2"

  # Check if both arguments were provided
  # Note: An empty expected string is allowed, but the parameter must be passed.
  if [[ $# -lt 2 ]]; then
    echo "Usage: check_command_output <command_string> <expected_output_string>" >&2
    echo "Example: check_command_output 'echo hello' 'hello'" >&2
    return 2
  fi

  # --- Execute the command and capture its standard output ---
  # IMPORTANT SECURITY WARNING:
  # Executing arbitrary command strings passed as arguments can be dangerous
  # if the input is not properly sanitized or controlled.
  # Use 'bash -c' to execute the command string.
  # We capture only stdout. stderr is ignored (redirected to /dev/null).
  # If you need to check stderr or the command's exit code, modify this part.
  local actual_output
  actual_output=$(bash -c "$command_to_run" 2>/dev/null)
  local command_exit_status=$? # Optional: capture the command's exit status

  # Optional: Check if the command executed successfully (exit status 0)
  # You might want to return a different error code if the command itself failed.
  if [[ $command_exit_status -ne 0 ]]; then
    echo "Warning: Command '$command_to_run' failed with exit status $command_exit_status." >&2
    # Decide if a failed command should be treated as a non-match or a specific error
    # return 3 # Example: Use a specific code for command execution failure
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

if is_in_path "tailscale"
then
  echo "tailscale in path"
else
  echo "tailscale NOT in path"
fi

if check_command_output "tailscale status" "failed to connect to local tailscaled; it doesn't appear to be running (sudo systemctl start tailscaled ?)"
then
  echo "failed to connect to local tailscaled"
else
  echo "connected to tailscaled"
fi
