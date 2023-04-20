#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
set -x
logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

rk_state_dir=$XDG_RUNTIME_DIR/usernetes/rootlesskit
port=$(rootlessctl --socket $rk_state_dir/api.sock list-ports --json | jq '.spec.parentPort')
if [ -z "$port" ]
then
  rootlessctl --socket $rk_state_dir/api.sock add-ports $U7S_ROOTLESSKIT_PORTS
fi

cmd=$(yq '.spec.containers[0].command | join(" ")' /etc/kubernetes/manifests/kube-apiserver.yaml)
cmd=${cmd:1:-1}

eval  $(setEnvsByYaml /etc/kubernetes/manifests/kube-apiserver.yaml)
cmd+=" --kubelet-certificate-authority=$client_ca_file "

$cmd $@
