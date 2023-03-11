#!/bin/sh
while :; do socat pty,link=/dev/ttyUSB1,raw,user=0,group=0,mode=777 tcp:192.168.0.11:3334; sleep 1; done &
