#!/bin/bash

if ! /sbin/systemctl --no-pager --user status u7s-rootlesskit.service >/dev/null 2>&1
then
  /sbin/systemctl --user -T start u7s-rootlesskit.service
fi
if /sbin/systemctl --no-pager --user status u7s-kubelet-crio.service >/dev/null 2>&1
then
  /sbin/systemctl --user -T start  u7s-kubelet-crio.service
fi
rm -rf /var/lib/u7s-admin/.config/usernetes/pki
mkdir /var/lib/u7s-admin/.config/usernetes/pki

export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

uid=$(id -u u7s-admin)
$(dirname $0)/nsenter.sh rm -rf /etc/kubernetes/*
$(dirname $0)/nsenter.sh rm -rf /var/lib/etcd
$(dirname $0)/nsenter.sh mkdir /var/lib/etcd

exec $(dirname $0)/nsenter.sh \
  /usr/bin/kubeadm init \
  -v 9 \
  --cert-dir=/var/lib/u7s-admin/.config/usernetes/pki \
  --pod-network-cidr=10.0.42.0/24 \
  --kubernetes-version=1.26.3 \
  --cri-socket /run/user/$uid/usernetes/crio/crio.sock \
  --image-repository=registry.local/k8s-p10 \
  --ignore-preflight-errors all
#  --config kubeadm_config.yaml
#  --feature-gates RootlessControlPlane=true \
