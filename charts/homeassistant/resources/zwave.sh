#!/bin/sh
apk add socat
while :; do socat pty,link=/dev/ttyUSB0,raw,user=0,group=0,mode=777 tcp:192.168.0.111:3333; sleep 1; done &