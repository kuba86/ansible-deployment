FROM docker.io/restic/restic:0.18.1 AS restic_source
FROM docker.io/goacme/lego:v4.30.1 AS lego_source
FROM docker.io/rclone/rclone:1.72.0 AS rclone_source
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
COPY --from=lego_source /lego /usr/bin/lego
COPY --from=rclone_source /usr/local/bin/rclone /usr/bin/rclone

WORKDIR /data

COPY files/lets-encrypt/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
