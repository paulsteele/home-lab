#!/usr/bin/env bash

for file in "$@"
do
  if [ ! -d $file ]; then
    exit
  fi
  echo "Filtering CRD's from $file"
  tempfile="$file.tmp"
  tempdir="tempdir"
  rm -rf $tempdir
  mkdir $tempdir

  tar -xf $file -C $tempdir
  rm -rf $tempdir/**/crds
  cd $tempdir
  tar -czf ../$tempfile *
  cd -
  rm -rf $tempdir
  mv $tempfile $file
done
