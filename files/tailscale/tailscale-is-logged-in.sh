#! /usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

check_command_output() {
  local command_to_run="$1"
  local expected_output="$2"

  # Check if both arguments were provided
  # Note: An empty expected string is allowed, but the parameter must be passed.
  if [[ $# -lt 2 ]]; then
    echo "Usage: check_command_output <command_string> <expected_output_string>" >&2
    echo "Example: check_command_output 'echo hello' 'hello'" >&2
    return 1
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
    echo "Warning: Command failed with exit status $command_exit_status. The command: '$command_to_run'" >&2
    # Decide if a failed command should be treated as a non-match or a specific error
    # exit 1 # Example: Use a specific code for command execution failure
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

if check_command_output "tailscale status --peers=false" "failed to connect to local tailscaled; it doesn't appear to be running (sudo systemctl start tailscaled ?)"
then
  echo "tailscale is not running"
elif check_command_output "tailscale status --peers=false" "faile"
then
  echo ""
else
  echo ""
fi
