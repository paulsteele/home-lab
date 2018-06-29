#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --key)
  KEY="$2"
  shift
  shift
  ;;
  *)
  POSITIONAL+=("$1")
  shift
  ;;
esac
done
set -- "${POSITIONAL[@]}"

if [ -z "$KEY" ]; then
  echo "need to specify --key"
  exit 1
fi

kubectl create secret generic firefly-token --from-literal=FF_APP_KEY=$KEY
