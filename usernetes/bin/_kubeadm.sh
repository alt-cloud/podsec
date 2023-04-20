#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

set -x
logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

rm -rf /var/lib/u7s-admin/.config/usernetes/pki
mkdir /var/lib/u7s-admin/.config/usernetes/pki
rm -rf /var/lib/etcd
mkdir /var/lib/etcd

uid=$(id -u u7s-admin)
socket="unix:///run/user/$uid/usernetes/crio/crio.sock"
# echo KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=$socket --pod-infra-container-image=registry.local/k8s-p10/pause:3.9" > /var/lib/kubelet/kubeadm-flags.env

/usr/bin/kubeadm init \
  -v 9 \
  --cert-dir=/var/lib/u7s-admin/.config/usernetes/pki \
  --pod-network-cidr=10.0.42.0/24 \
  --kubernetes-version=1.26.3 \
  --cri-socket $socket \
  --image-repository=registry.local/k8s-p10 \
  --apiserver-cert-extra-sans=127.0.0.1 \
  --control-plane-endpoint=192.168.122.83 \
  --ignore-preflight-errors all \
  $@
#  --config kubeadm_config.yaml
#  --feature-gates RootlessControlPlane=true \
