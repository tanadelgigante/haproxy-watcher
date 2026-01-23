FROM alpine:3.22

RUN apk add --no-cache inotify-tools docker-cli bash

COPY entrypoint.sh /entrypoint.sh
COPY watcher.sh /watcher.sh

RUN chmod +x /entrypoint.sh /watcher.sh

ENTRYPOINT ["/entrypoint.sh"]