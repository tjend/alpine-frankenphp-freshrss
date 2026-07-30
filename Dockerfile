# based on https://frankenphp.dev/docs/docker/#running-with-no-capabilities

ARG PHP_VERSION="8.4.16"
FROM docker.io/dunglas/frankenphp:php${PHP_VERSION}-alpine

# run frankenphp as this user
ARG USER="appuser"
# don't expose php version in response headers
ENV FRANKENPHP_CONFIG="php_ini expose_php off"
# run the app on port 8080
ENV SERVER_NAME=":8080"
# FreshRSS's public directory
ENV SERVER_ROOT="/app/p"

# hadolint global ignore=DL3018 # install the latest version of apk packages
# hadolint global ignore=DL4006 # bug, see https://github.com/hadolint/hadolint/issues/806
RUN <<EOF
  # ensure script errors fail hard and fast on error + display command being run
  set -eoux pipefail

  # add user
  adduser -D "${USER}"

  # remove default capability of frankenphp allowing privileged ports
  setcap -r /usr/local/bin/frankenphp

  # give write access to frankenphp's caddy directories
  chown -R "${USER}:${USER}" /config/caddy /data/caddy

  # remove default website
  rm -rf /app/public

  # add php extensions
  install-php-extensions intl zip

  # freshrss
  wget -q -O - https://github.com/FreshRSS/FreshRSS/archive/refs/heads/latest.tar.gz | tar zx -C /app --strip-component 1
  /app/cli/prepare.php
  /app/cli/do-install.php --allow-anonymous --allow-anonymous-refresh --api-enabled --auth-type="none" --default-user="admin" --disable-update
  /app/cli/create-user.php --language="en" --user="admin"
  chown -R "${USER}:${USER}" /app/data

  # freshrss extensions
  mkdir /tmp/ext
  wget -q -O - https://github.com/langfeld/FreshRSS-extensions/archive/refs/heads/master.tar.gz | tar zx -C /tmp/ext --strip-component 1
  mkdir /tmp/ext/xExtension-TitleDecode
  wget -q -O - https://github.com/tjend/freshrss-title-decode-extension/archive/refs/heads/master.tar.gz | tar zx -C /tmp/ext/xExtension-TitleDecode --strip-component 1
  mv "/tmp/ext/xExtension-"* "/app/extensions"
  rm -rf /tmp/ext

  # add cron
  apk --no-cache add supercronic
  echo "27 * * * * /app/app/actualize_script.php # hourly" > /etc/crontab
EOF

USER ${USER}

# custom install check script
COPY check-install.php /app/check-install.php

# check install
RUN php /app/check-install.php
