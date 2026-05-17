#!/bin/sh

if [ -n "$DEBUG" ]; then
  set -x
fi

# /config が空の場合、デフォルト設定をコピー
if [ -z "$(ls -A /config 2>/dev/null)" ]; then
  echo >&2 "Creating default configs..."
  cp -r /opt/cfx-server-data/* /config
  RCON_PASS="${RCON_PASSWORD-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16)}"
  sed -i "s/{RCON_PASS}/${RCON_PASS}/g" /config/server.cfg
  echo >&2 "----------------------------------------------"
  echo >&2 "RCON password is set to: ${RCON_PASS}"
  echo >&2 "----------------------------------------------"
fi

# /resources がマウントされている場合、シンボリックリンクを作成
if [ -d "/resources" ] && [ "$(ls -A /resources 2>/dev/null)" ]; then
  echo >&2 "Linking external resources..."
  for dir in /resources/*/; do
    if [ -d "$dir" ]; then
      basename="$(basename "$dir")"
      target="/config/resources/${basename}"
      if [ ! -e "$target" ]; then
        ln -sf "$dir" "$target"
        echo >&2 "  Linked: ${basename}"
      fi
    fi
  done
fi

if [ -z "$NO_ONESYNC" ]; then
  ONESYNC_ARGS="+set onesync on +set onesync_population true"
fi

CONFIG_ARGS=
if [ -z "${NO_DEFAULT_CONFIG}" ]; then
  CONFIG_ARGS="$CONFIG_ARGS $ONESYNC_ARGS +exec /config/server.cfg"
fi

if [ -z "${NO_LICENSE_KEY}${NO_LICENCE_KEY}" ]; then
  if [ -z "${LICENSE_KEY}" ] && [ -n "${LICENCE_KEY}" ]; then
    LICENSE_KEY="${LICENCE_KEY}"
  fi

  if [ -z "${NO_DEFAULT_CONFIG}" ] && [ -z "${LICENSE_KEY}" ]; then
    echo >&2 "License key not found in environment, please create one at https://keymaster.fivem.net!"
    exit 1
  fi
fi

export TXHOST_DATA_PATH="/txData"

exec /opt/cfx-server/ld-musl-x86_64.so.1 \
  --library-path "/usr/lib/v8/:/lib/:/usr/lib/" \
  -- \
  /opt/cfx-server/FXServer \
  +set citizen_dir /opt/cfx-server/citizen/ \
  $CONFIG_ARGS \
  "$@"
