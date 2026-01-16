#! /usr/bin/env fish

read -P "Proceed with decrypting dysk? (y/N): " -l confirm_decrypt
if test "$confirm_decrypt" != "y"
    echo "Decryption aborted."
else
    sudo cryptsetup \
        open \
        /dev/disk/by-id/usb-Samsung_SSD_860_QVO_2TB_012345678999-0:0 \
        luks-2tb-ssd && \
    sudo mount \
        -o compress=zstd:3 \
        --source /dev/mapper/luks-2tb-ssd \
        --target /var/mnt/2tb-ssd \
        --onlyonce
end

disk.info

read -P "Proceed with BTRFS Scrub? (y/N): " -l confirm_scrub
if test "$confirm_scrub" != "y"
    echo "BTRFS Scrub aborted."
else
    cmd-monitor \
        --check-time=10 \
        --check-command="sudo btrfs scrub status /var/mnt/2tb-ssd" \
        --command-background="true" \
        --command="sudo btrfs scrub start /var/mnt/2tb-ssd" \
        --running-grep="status finished"
end

read -P "Proceed with rsync? (y/N): " -l confirm_rsync
if test "$confirm_rsync" != "y"
    echo "rsync aborted."
else
    rsync \
        --archive \
        --info=progress2,stats2 \
        --human-readable \
        --exclude='/syncthing/Kuba-media-download' \
        /var/mnt/data1/syncthing /var/mnt/2tb-ssd/
end

read -P "Proceed with umount? (y/N): " -l confirm_umount
if test "$confirm_umount" != "y"
    echo "umount aborted."
else
    sudo umount /var/mnt/2tb-ssd && \
    sudo cryptsetup close luks-2tb-ssd && \
    echo "Backup process completed successfully."
end
