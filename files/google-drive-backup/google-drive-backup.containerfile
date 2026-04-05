FROM docker.io/restic/restic:0.18.1 AS restic_source
FROM docker.io/rclone/rclone:1.73.3 AS rclone_source
FROM docker.io/alpine:3

RUN apk update \
    && apk add --no-cache \
    ca-certificates \
    fuse \
    openssh-client \
    tzdata \
    jq \
    fish \
    && update-ca-certificates

COPY --from=restic_source /usr/bin/restic /usr/bin/restic
COPY --from=rclone_source /usr/local/bin/rclone /usr/bin/rclone
COPY google-drive-rclone-backup.fish /rclone-backup.fish
COPY google-drive-restic-backup.fish /restic-backup.fish

RUN chmod +x /rclone-backup.fish && chmod +x /restic-backup.fish

WORKDIR /
ENTRYPOINT ["/usr/bin/fish"]
