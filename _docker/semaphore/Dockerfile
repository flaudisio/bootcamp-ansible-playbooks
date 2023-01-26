FROM python:3.10-alpine

# Dependencies

RUN set -ex \
 && apk add --no-cache \
        ca-certificates \
        curl \
        gcompat \
        git \
        mariadb-client \
        openssh-client-default \
        sshpass \
 && curl -L -o /sbin/gosu "https://github.com/tianon/gosu/releases/download/1.16/gosu-amd64" \
 && curl -L -o /sbin/tini "https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-amd64" \
 && chmod -v 755 /sbin/gosu /sbin/tini

# Semaphore

ENV SEMAPHORE_TMP_PATH=/tmp/semaphore \
    SEMAPHORE_CONFIG_PATH=/etc/semaphore \
    SEMAPHORE_DB_PATH=/data/semaphore

RUN set -ex \
 && addgroup -g 786 semaphore \
 && adduser -h /home/semaphore -D -u 786 -G semaphore semaphore

ARG semaphore_version=2.8.77

RUN set -ex \
 && curl -sSL \
        "https://github.com/ansible-semaphore/semaphore/releases/download/v${semaphore_version}/semaphore_${semaphore_version}_linux_amd64.tar.gz" \
        | tar -xvz -f - semaphore \
 && mv -v semaphore /usr/local/bin/semaphore \
 && chown -v root:root /usr/local/bin/semaphore \
 && chmod -v 755 /usr/local/bin/semaphore \
 && curl -sSL -o /usr/local/bin/semaphore-wrapper \
        "https://raw.githubusercontent.com/ansible-semaphore/semaphore/v${semaphore_version}/deployment/docker/common/semaphore-wrapper" \
 && chown -v root:root /usr/local/bin/semaphore-wrapper \
 && chmod -v 755 /usr/local/bin/semaphore-wrapper

# Ansible

COPY _requirements/control-nodes.txt /tmp/requirements.txt

RUN set -ex \
 && apk add --no-cache --virtual .build-deps \
        gcc \
        libffi-dev \
        make \
        musl-dev \
        openssl-dev \
 && pip install --no-cache-dir -r /tmp/requirements.txt \
 && apk del --no-cache --purge .build-deps \
    \
 && ansible --version \
    \
 && find /usr/local -depth -type d -name '__pycache__' -exec rm -rf '{}' \; \
 && rm -rf ~/.cache

# Image setup

COPY _docker/semaphore/entrypoint.sh /sbin/entrypoint.sh

VOLUME ["$SEMAPHORE_TMP_PATH"]

ENTRYPOINT ["tini", "--", "/sbin/entrypoint.sh"]

CMD ["semaphore", "server", "--config", "$SEMAPHORE_CONFIG_PATH"]
