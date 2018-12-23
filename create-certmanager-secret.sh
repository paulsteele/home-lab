#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --secret-key)
  KEY="$2"
  shift
  shift
  ;;
esac
done
set -- "${POSITIONAL[@]}"

if [ -z "$KEY" ]; then
  echo "need to specify --secret-key"
  exit 1
fi

kubectl create secret generic route53-key --from-literal=key=$KEY
