#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
# set -x
uid=$(id -u)

if [ $uid -eq 0 ]
then
  exec $U7S_BASE_DIR/bin/_etcd.sh $@
else
  exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_etcd.sh $@
fi
