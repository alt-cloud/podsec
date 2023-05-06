#!/bin/sh

source ~u7s-admin/.config/usernetes/env

ip a add  $U7S_TAPIP/12 dev $U7S_EXTDEV
iptables -I POSTROUTING -t nat -d 10.96.0.0/12 -j SNAT --to $U7S_TAPIP
if [ U7S_CONTROLPLANE = 'initMaster' ]
then
  ip a add  10.96.0.10/12 dev $U7S_EXTDEV
  iptables -t nat -I PREROUTING -p tcp -d 0.0.0.0/0 --dport 53 -j DNAT --to=10.96.0.1:6053
  iptables -t nat -I PREROUTING -p udp -d 0.0.0.0/0 --dport 53 -j DNAT --to=10.96.0.1:6053
fi

echo "0 2147483647"  > /proc/sys/net/ipv4/ping_group_range

