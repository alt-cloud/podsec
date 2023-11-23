#!/bin/sh

case $1 in
start)
  /sbin/systemctl --user -T start rootlesskit
  /sbin/systemctl --user -T start  kubelet
  sleep  infinity
  break;
  ;;
stop)
  /sbin/systemctl --user -T stop rootlesskit
  /sbin/systemctl --user -T stop  kubelet
esac
