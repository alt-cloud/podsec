#!/bin/sh
source podsec-u7s-functions
source $envFile

echo "0 2147483647"  > /proc/sys/net/ipv4/ping_group_range

