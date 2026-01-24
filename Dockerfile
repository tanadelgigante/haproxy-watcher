FROM alpine:3.22

RUN apk add --no-cache inotify-tools docker-cli bash

COPY entrypoint.sh /entrypoint.sh
COPY watcher.sh /watcher.sh

RUN chmod +x /entrypoint.sh /watcher.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ps aux | grep -q '[i]notifywait' || exit 1

ENTRYPOINT ["/entrypoint.sh"]