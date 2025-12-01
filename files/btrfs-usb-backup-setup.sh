#!/bin/bash

set -euo pipefail

# Devices and labels
DEVICES=("/dev/sda" "/dev/sdb")
LABELS=("backup-01" "backup-02")

# Function to confirm before destructive steps
confirm() {
  read -rp "$1 [y/N] " answer
  case "$answer" in
    [Yy]* ) ;;
    * ) echo "Aborting."; exit 1 ;;
  esac
}

for i in "${!DEVICES[@]}"; do
  DEV="${DEVICES[$i]}"
  LABEL="${LABELS[$i]}"

  echo "Preparing $DEV as $LABEL"
  confirm "WARNING: All data on $DEV will be erased. Continue?"

  # Wipe filesystem signatures
  sudo wipefs -a "$DEV"

  # Set up LUKS encryption
  echo "Setting up LUKS on $DEV..."
  sudo cryptsetup luksFormat "$DEV"
  sudo cryptsetup open "$DEV" "$LABEL"

  # Create Btrfs filesystem with profiles and compression
  echo "Creating btrfs filesystem on /dev/mapper/$LABEL..."
  sudo mkfs.btrfs \
    --label "$LABEL" \
    --data dup \
    --metadata dup \
    "/dev/mapper/$LABEL"

  # Mount, set compression, unmount
  MNTDIR="/mnt/$LABEL"
  sudo mkdir -p "$MNTDIR"
  sudo mount "/dev/mapper/$LABEL" "$MNTDIR"
  echo "Setting compression=zstd:1..."
  sudo btrfs property set "$MNTDIR" compression zstd:1
  sudo umount "$MNTDIR"
  sudo cryptsetup close "$LABEL"
  echo "$LABEL on $DEV set up successfully."
done

echo "All done."
