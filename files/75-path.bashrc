# Add a directory to PATH (prepend) only if it's not there already
add_path_prepend() {
  local dir="$1"
  [ -z "$dir" ] && return 0
  # Optional: only add if it exists
  [ -d "$dir" ] || return 0

  case ":$PATH:" in
    *":$dir:"*) : ;;                 # already present
    *) export PATH="$dir${PATH:+:$PATH}" ;;
  esac
}

# Add a directory to PATH (append) only if it's not there already
add_path_append() {
  local dir="$1"
  [ -z "$dir" ] && return 0
  # Optional: only add if it exists
  [ -d "$dir" ] || return 0

  case ":$PATH:" in
    *":$dir:"*) : ;;                 # already present
    *) export PATH="${PATH:+$PATH:}$dir" ;;
  esac
}

add_path_append "$HOME/.local/bin"
add_path_append "$HOME/bin"
