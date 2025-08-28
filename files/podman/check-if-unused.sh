set -euo pipefail
IFS=$'\n\t'

image_store_count=$(podman info --format "{{ .Store.ImageStore }}")
echo "image_store_count: $image_store_count"
if [[ "$image_store_count" != "{0}" ]]; then
  echo "podman is used, clean up first and re-run"
else
  echo "podman is unused, ok to reset"
fi
