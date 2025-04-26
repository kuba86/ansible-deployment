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

# verify_apps_are_available
# create_list_of_jdk_paths_env_var
# create_java_home_vendor_version_env_var
