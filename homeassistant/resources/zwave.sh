#!/bin/bash
case "$1" in 
    start)
      socat pty,link=/dev/ttyUSB0,raw,user=0,group=0,mode=777 tcp:192.168.0.110:3333 &
      ;;
    stop)
      stop
      ;;
    restart)
      stop
      start
      ;;
    status)
      ;;
    *)
      echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0 