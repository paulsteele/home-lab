#!/bin/sh
set -eu

if ! command -v ser2net >/dev/null 2>&1; then
  apk add --no-cache ser2net
fi

CONFIG=/tmp/ser2net.yaml
/usr/local/libexec/ser2net/discover.sh > "$CONFIG"
echo 'Generated ser2net configuration:'
cat "$CONFIG"

# An empty mapping is a valid pre-configuration state. ser2net rejects the
# comment-only file produced by discover.sh, so keep the DaemonSet alive until
# a USB mapping is configured instead of entering CrashLoopBackOff.
if ! grep -q '^connection:' "$CONFIG"; then
  echo 'No configured USB serial devices; waiting for serialMappings.'
  exec tail -f /dev/null
fi

exec ser2net -d -l -c "$CONFIG"
