ARG go_crond_version
FROM webdevops/go-crond:${go_crond_version}-alpine AS builder

FROM alpine:3.17

ENV SEMAPHORE_TMP_PATH=/semaphore/tmp \
    SCHEDULE="0 * * * *"

COPY --from=builder /usr/local/bin/go-crond /usr/local/bin/go-crond

COPY _docker/semaphore-housekeeper/entrypoint.sh /sbin/entrypoint.sh
COPY _docker/semaphore-housekeeper/housekeeper.sh /usr/local/bin/housekeeper

ENTRYPOINT ["/sbin/entrypoint.sh"]

CMD ["run"]
