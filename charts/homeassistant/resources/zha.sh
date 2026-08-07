#!/bin/sh
# ser2net is a Helmfile-managed Service; do not couple this bridge to a node IP.
while :; do socat pty,link=/dev/ttyUSB1,raw,user=0,group=0,mode=777 tcp:ser2net.default.svc.cluster.local:3334; sleep 1; done &
