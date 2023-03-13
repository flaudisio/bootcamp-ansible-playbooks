FROM python:3.10-alpine

# Dependencies

ARG gosu_version=1.16
ARG tini_version=0.19.0

# hadolint ignore=DL3018
RUN set -ex \
 && apk add --no-cache \
        ca-certificates \
        curl \
        gcompat \
        gettext \
        git \
        mariadb-client \
        openssh-client-default \
        sshpass \
 && DL_ARCH=amd64 \
 && if [ "$( arch )" = "aarch64" ] ; then DL_ARCH=arm64 ; fi \
 && curl -L -o /sbin/gosu "https://github.com/tianon/gosu/releases/download/${gosu_version}/gosu-${DL_ARCH}" \
 && curl -L -o /sbin/tini "https://github.com/krallin/tini/releases/download/v${tini_version}/tini-static-${DL_ARCH}" \
 && chmod -v 755 /sbin/gosu /sbin/tini

# Semaphore

ENV SEMAPHORE_USER=semaphore \
    SEMAPHORE_TMP_PATH=/semaphore/tmp \
    SEMAPHORE_CONFIG_PATH=/semaphore/etc \
    SEMAPHORE_DB_PATH=/semaphore/db

RUN set -ex \
 && addgroup -g 786 "$SEMAPHORE_USER" \
 && adduser -h "/home/$SEMAPHORE_USER" -D -u 786 -G "$SEMAPHORE_USER" "$SEMAPHORE_USER"

ARG semaphore_version=2.8.77

# hadolint ignore=DL3018,DL4006
RUN set -ex \
 && DL_ARCH=amd64 \
 && if [ "$( arch )" = "aarch64" ] ; then DL_ARCH=arm64 ; fi \
 && curl -sSL \
        "https://github.com/ansible-semaphore/semaphore/releases/download/v${semaphore_version}/semaphore_${semaphore_version}_linux_${DL_ARCH}.tar.gz" \
        | tar -xvz -f - semaphore \
 && mv -v semaphore /usr/local/bin/semaphore \
 && chown -v root:root /usr/local/bin/semaphore \
 && chmod -v 755 /usr/local/bin/semaphore

# Ansible

COPY _requirements/control-nodes.txt /tmp/requirements.txt

# hadolint ignore=DL3018
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

# Ref: https://docs.ansible-semaphore.com/administration-guide/configuration#configuration-file
COPY _docker/semaphore/config.json.tpl /etc/config.json.tpl

COPY _docker/semaphore/entrypoint.sh /sbin/entrypoint.sh

VOLUME ["$SEMAPHORE_TMP_PATH"]

ENTRYPOINT ["tini", "--", "/sbin/entrypoint.sh"]

CMD ["semaphore", "server", "--config", "$SEMAPHORE_CONFIG_PATH"]
