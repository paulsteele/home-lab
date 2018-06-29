#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --claim)
    CLAIM="$2"
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

if [ -z "$CLAIM" ]; then
  echo "need to specify --claim"
  exit 1
fi


kubectl create secret generic plex --from-literal=PLEX_CLAIM=$CLAIM
