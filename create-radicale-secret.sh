#!/bin/bash

PASS=`openssl passwd -apr1`
HTPASSWD="paulsteele:$PASS"

echo $HTPASSWD

kubectl create secret generic radicale-secret --from-literal=httpasswd=$HTPASSWD
