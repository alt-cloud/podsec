#!/bin/bash

logger  "=============================================== KUBEADM ====================================="

set -x
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
if ! /sbin/systemctl --no-pager --user status rootlesskit.service >/dev/null 2>&1
then
  /sbin/systemctl --user -T start rootlesskit.service
fi
# if /sbin/systemctl --no-pager --user status kubelet-crio.service >/dev/null 2>&1
# then
#   /sbin/systemctl --user -T start  kubelet-crio.service
# fi

exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_kubeadm.sh $@


