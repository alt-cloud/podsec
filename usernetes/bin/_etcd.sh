#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
set -x
echo "UID=$UID"

cmd=$(yq '.spec.containers[0].command | join(" ")' /etc/kubernetes/manifests/etcd.yaml)
cmd=${cmd:1:-1}
cmd+=" --enable-v2=true "

/usr/sbin/$cmd $@
