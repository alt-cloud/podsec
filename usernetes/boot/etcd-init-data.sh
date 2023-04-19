#!/bin/bash
set -x
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

uid=$(id -u)
echo "$0: uid=$uid"

if [ $uid -eq 0 ]
then
  exec $U7S_BASE_DIR/bin/_etcd-init-data.sh $@
else
	exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_etcd-init-data.sh $@
fi

