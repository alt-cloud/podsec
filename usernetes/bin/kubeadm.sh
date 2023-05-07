#!/bin/sh

logger  "=============================================== KUBEADM ====================================="

source podsec-u7s-functions

envDir=$(dirname $envFile)
mkdir -p $envDir
cp /etc/podsec/u7s/config/env $envFile

source $envFile

# set -x
cmd=$1

# uid=$(id -u)
# echo "$0: uid=$uid"
# export XDG_RUNTIME_DIR="/run/user/$uid/"

if ! /sbin/systemctl --no-pager --user status rootlesskit.service >/dev/null 2>&1
then
  /sbin/systemctl --user -T start rootlesskit.service
fi


nsenter_u7s _kubeadm.sh "$cmd"


