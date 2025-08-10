set -o pipefail

coursier_jdk_path="${HOME}"/.cache/coursier/arc/

verify_apps_are_available() {
  # make sure all program used are available
  which fd > /dev/null || return 0
  which sort > /dev/null || return 0
  which grep > /dev/null || return 0
  which awk > /dev/null || return 0
}

create_list_of_jdk_paths_env_var() {
  # Find java executables, sort them
  local check_if_fd_finds_any_jvm=$(fd --exclude 'jre' --type f '^java$' "$coursier_jdk_path")
  if [ -z "$check_if_fd_finds_any_jvm" ]; then
    echo "no JVM's found in $coursier_jdk_path"
    return 0
  fi

  coursier_java_list=$(fd --exclude 'jre' --type f '^java$' "$coursier_jdk_path" -x echo {//} | sort)

  if [ -z "$coursier_java_list" ]; then
      echo "No Java installation found in coursier cache"
      return 0
  fi
}

create_java_home_vendor_version_env_var() {
  while read -r java_path; do
    if [ -d "$java_path" ]; then
      local java_output=$("$java_path/java" -XshowSettings:properties -version 2>&1)
      local java_version=$(echo "$java_output" \
      | grep 'java.vm.specification.version' \
      | awk -F'= ' '{print $2}' \
      | awk -F'.' '{if ($1 =="1") print $2; else print $1}')
      local java_vendor=$(echo "$java_output" | grep 'java.vm.vendor' | awk -F'= ' '{print $2}')

      case "$java_vendor" in
        "Eclipse Adoptium" | "Temurin")
          java_vendor="temurin"
          ;;
        "GraalVM Community")
          java_vendor="graalvm"
          ;;
        *)
          java_vendor="other"
          ;;
      esac

      # if vendor is known, export JAVA_HOME with vendor and version
      if [ "$java_vendor" != "other" ]; then
          export JAVA_HOME_"${java_vendor^^}"_"${java_version}"="${java_path%/bin}"
      fi
    fi
  done <<< "$coursier_java_list"
}

verify_apps_are_available
create_list_of_jdk_paths_env_var

if [ "$(uname -m)" = "aarch64" ]; then
  export JAVA_HOME_GRAALVM_17="${HOME}/.cache/coursier/arc/https/github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.3.3/graalvm-ce-java17-linux-aarch64-22.3.3.tar.gz/graalvm-ce-java17-22.3.3"
else
  create_java_home_vendor_version_env_var
fi

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
    # remove_from_path_env_var "$jdk_path"
    export JAVA_HOME="$JAVA_HOME_GRAALVM_17"
    export PATH="$PATH:${JAVA_HOME}/bin"
  fi
}

set_java_home_and_update_path_env_var
