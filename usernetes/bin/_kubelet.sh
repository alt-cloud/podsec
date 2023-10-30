#!/bin/sh
source podsec-u7s-functions
source $envFile
source /etc/podsec/u7s/env/platform
# source "/etc/podsec/u7s/env/$U7S_PLATFORM"
logger  "=============================================== KUBELET ====================================="

# set -x
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
	--cert-dir /etc/kubernetes/pki \
	--root-dir $XDG_DATA_HOME/usernetes/kubelet \
	--bootstrap-kubeconfig "/etc/kubernetes/bootstrap-kubelet.conf" \
	--kubeconfig "/etc/kubernetes/kubelet.conf" \
	--config $kubelet_config \
	--container-runtime-endpoint=$socket \
	--pod-infra-container-image="$U7S_REGISTRY/$U7S_PAUSE_IMAGE" \
	$@
