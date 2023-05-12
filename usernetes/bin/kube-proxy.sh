#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

uid=$(id -u)
echo "$0: uid=$uid"
if [ $uid -eq 0 ]
then
  exec $U7S_BASE_DIR/bin/_kube-proxy.sh $@
else
  exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_kube-proxy.sh $@
fi

