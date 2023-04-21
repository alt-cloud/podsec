#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

set -x
logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n"  >&2

mkdir -p $XDG_RUNTIME_DIR/usernetes
TMPFILE=$(mktemp "/tmp/kubeconf.XXXXXX")
kubelet_config="/var/lib/kubelet/config.yaml"
if cat $kubelet_config |
	yq -y  '.+{'"volumePluginDir: \"$XDG_DATA_HOME/usernetes/kubelet-plugins-exec\""',
		"cgroupDriver":"cgroupfs",
		"failSwapOn": false,
		"featureGates":{"KubeletInUserNamespace": true},
		"evictionHard":{"nodefs.available": "3%"},
		"localStorageCapacityIsolation": false,
		"cgroupsPerQOS": true,
		"enforceNodeAllocatable": []
		}'  >$TMPFILE
then
  mv $TMPFILE $kubelet_config
fi
uid=$(id -u u7s-admin)
socket="unix:///run/user/$uid/usernetes/crio/crio.sock"

kubelet \
	--cert-dir $XDG_CONFIG_HOME/usernetes/pki \
	--root-dir $XDG_DATA_HOME/usernetes/kubelet \
	--kubeconfig "/etc/kubernetes/kubelet.conf" \
	--config $kubelet_config \
	--container-runtime-endpoint=$socket \
	--pod-infra-container-image=registry.local/k8s-p10/pause:3.9 \
	$@
