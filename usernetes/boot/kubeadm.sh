#!/bin/sh

getExtIP() {
  set -- $(ip r | grep default)
  router=$3
  ifs=$IFS
  IFS=.
  set -- $router
  IFS=$ifs
  prefixIP=$1
  shift
  while [ $# -gt 1 ]; do prefixIP+=".$1"; shift; done
  set -- $(ip a | grep $prefixIP | grep inet)
  IFS=/
  set -- $2
  IFS=$ifs
  extIP=$1
  echo $extIP
}


logger  "=============================================== KUBEADM ====================================="


source ~u7s-admin/.config/usernetes/env
# set -x
cmd=$1
# apiServer=$2
# token=$3
# caCertHash=$4
# controlPlane=$5

uid=$(id -u)
echo "$0: uid=$uid"
export XDG_RUNTIME_DIR="/run/user/$uid/"

export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
if ! /sbin/systemctl --no-pager --user status rootlesskit.service >/dev/null 2>&1
then
  /sbin/systemctl --user -T start rootlesskit.service
fi

extIP=$(getExtIP)

if [ $uid -eq 0 ]
then
  $U7S_BASE_DIR/bin/_kubeadm.sh "$extIP" "$cmd" # "$apiServer" "$token" "$caCertHash" "$controlPlane"
else
  $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_kubeadm.sh "$extIP" "$cmd" #"$apiServer" "$token" "$caCertHash" "$controlPlane"
fi

