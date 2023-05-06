#!/bin/sh

logger  "=============================================== KUBEADM ====================================="


source /etc/podsec/u7s/env
# set -x
cmd=$1

uid=$(id -u)
echo "$0: uid=$uid"
export XDG_RUNTIME_DIR="/run/user/$uid/"

source u7s_functions
if ! /sbin/systemctl --no-pager --user status rootlesskit.service >/dev/null 2>&1
then
  /sbin/systemctl --user -T start rootlesskit.service
fi


/usr/libexec/podsec/u7s/bin/_kubeadm.sh "$cmd"


