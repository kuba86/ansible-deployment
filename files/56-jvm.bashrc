set -o pipefail

remove_from_path_env_var() {
  # Ensure exactly one argument (the substring) is provided
  if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    return 0
  fi

  local substring_to_remove="$1"
  local original_path="$PATH" # Work with the current PATH
  local new_path_array=()     # Array to hold the paths to keep
  local entry                 # Loop variable

  # Temporarily change IFS (Internal Field Separator) to ':' to split the PATH
  # Use 'read -r -a' to safely read the parts into an array, handling potential empty entries
  IFS=':' read -r -a path_entries <<< "$original_path"

  # Iterate over each entry in the PATH array
  for entry in "${path_entries[@]}"; do
    # Check if the entry is non-empty AND does NOT contain the substring
    if [[ -n "$entry" && "$entry" != *"$substring_to_remove"* ]]; then
      # If it doesn't contain the substring, add it to our new array
      new_path_array+=("$entry")
    fi
  done

  # --- Join the array back into a colon-separated string ---

  # Check if the resulting array is empty
  if [ ${#new_path_array[@]} -eq 0 ]; then
    # If no paths remain, set PATH to empty string
    export PATH=""
  else
    # Join the array elements with a colon using printf
    local joined_path
    joined_path=$(printf "%s:" "${new_path_array[@]}")
    # Remove the trailing colon added by printf
    export PATH="${joined_path%:}"
  fi

  # You can optionally uncomment the line below to see the result immediately
  # echo "New PATH: $PATH"

  return 0
}

set_java_home_and_update_path_env_var() {
  if [ -v JAVA_HOME_GRAALVM_17 ]; then
    remove_from_path_env_var "$jdk_path"
    export JAVA_HOME="$JAVA_HOME_GRAALVM_17"
    export PATH="${JAVA_HOME}/bin:$PATH"
  fi
}

set_java_home_and_update_path_env_var
