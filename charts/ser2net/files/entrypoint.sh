#!/bin/sh
set -eu

if ! command -v ser2net >/dev/null 2>&1; then
  apk add --no-cache ser2net
fi

CONFIG=/tmp/ser2net.yaml
/usr/local/libexec/ser2net/discover.sh > "$CONFIG"
echo 'Generated ser2net configuration:'
cat "$CONFIG"

exec ser2net -d -l -c "$CONFIG"
