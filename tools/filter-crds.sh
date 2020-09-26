#!/usr/bin/env bash

for file in "$@"
do
  echo "Removing CRD's from $file"
  tempfile=$file.tmp

  tar -czvf $tempfile --exclude='crds' $file
  mv $tempfile $file
done
