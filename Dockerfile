# based on https://frankenphp.dev/docs/docker/#running-with-no-capabilities

ARG PHP_VERSION="8.4.13"
FROM docker.io/dunglas/frankenphp:php${PHP_VERSION}-alpine

# run frankenphp as this user
ARG USER="appuser"
# don't expose php version in response headers
ENV FRANKENPHP_CONFIG="php_ini expose_php off"
# run the app on port 8080
ENV SERVER_NAME=":8080"
# FreshRSS's public directory
ENV SERVER_ROOT="/app/p"

RUN <<EOF
  # abort on errors, display command being run
  set -ex

  # add user
  adduser -D "${USER}"

  # remove default capability of frankenphp allowing privileged ports
  setcap -r /usr/local/bin/frankenphp

  # give write access to frankenphp's caddy directories
  chown -R "${USER}:${USER}" /config/caddy /data/caddy

  # remove default website
  rm -rf /app/public

  # freshrss
  wget -O - https://github.com/FreshRSS/FreshRSS/archive/refs/heads/latest.tar.gz | tar zx -C /app --strip-component 1
  /app/cli/prepare.php
  /app/cli/do-install.php --allow-anonymous --allow-anonymous-refresh --api-enabled --auth-type="none" --default-user="admin" --disable-update
  /app/cli/create-user.php --language="en" --user="admin"
  chown -R "${USER}:${USER}" /app/data

  # add cron
  apk --no-cache add supercronic
  echo "27 * * * * /app/app/actualize_script.php # hourly" > /etc/crontab
EOF

USER ${USER}
