#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

set -x
uid=$(id -u)
echo "$0: uid=$uid"

if [ $uid -eq 0 ]
then
  exec $U7S_BASE_DIR/bin/_flanneld.sh $@
else
  exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_flanneld.sh $@
fi
# FIXME: nodes should not require the master key.
# Currently nodes require the master key because flanneld and master
# share the same etcd cluster.
