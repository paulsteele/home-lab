#!/bin/sh
socat pty,link=/dev/ttyUSB0,raw,user=0,group=0,mode=777 tcp:192.168.0.110:3333 &
