#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --token)
    TOKEN="$2"
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

if [ -z "$TOKEN" ]; then
  echo "need to specify --token"
  exit 1
fi


kubectl -n deployments create secret generic teyler-bot-token --from-literal=discordToken=$TOKEN
