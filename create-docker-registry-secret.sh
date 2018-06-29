#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --password)
  PASSWORD="$2"
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

if [ -z "$PASSWORD" ]; then
  echo "need to specify --password"
  exit 1
fi

kubectl create secret docker-registry registry.paul-steele.com --docker-server=registry.paul-steele.com --docker-username=paulsteele --docker-password=$PASSWORD --docker-email=paul_steele@live.com

kubectl -n deployments create secret docker-registry registry.paul-steele.com --docker-server=registry.paul-steele.com --docker-username=paulsteele --docker-password=$PASSWORD --docker-email=paul_steele@live.com
