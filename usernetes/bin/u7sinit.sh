#!/bin/sh

source ~u7s-admin/.config/usernetes/env

ip a add  $U7S_TAPIP/12 dev $U7S_EXTDEV
iptables -I POSTROUTING -t nat -d 10.96.0.0/12 -j SNAT --to $U7S_TAPIP

echo "0 2147483647"  > /proc/sys/net/ipv4/ping_group_range

