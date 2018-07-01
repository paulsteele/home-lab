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
  --root-password)
  ROOT_PASSWORD="$2"
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

if [ -z "$PASSWORD" ] || [ -z "$ROOT_PASSWORD" ]; then
  echo "need to specify --password"
  echo "need to specify --root-password"
  exit 1
fi

kubectl create secret generic database-mysql --from-literal=mysql-password=$PASSWORD --from-literal=mysql-root-password=$ROOT_PASSWORD
