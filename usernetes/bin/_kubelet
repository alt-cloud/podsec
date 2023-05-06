#!/bin/sh
source u7s_finctions

set -x
logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n"  >&2

# Обеспечить доступ с cni0 интерфеса сети 10.244.0.1/24  доступ к внешним и внутранним анонсированным адресам (порты tcp/6443, udp/53, ...)
iptables -t nat -I POSTROUTING -s 10.244.0.1/24  -j SNAT --to $U7S_TAPIP
# Обеспечить доступ к порту 10.96.0.10:53 через порт 6053
# iptables -t nat -I PREROUTING -p tcp -d 0.0.0.0/0 --dport 6053 -j DNAT --to=10.96.0.10:53
# iptables -t nat -I PREROUTING -p udp -d 0.0.0.0/0 --dport 6053 -j DNAT --to=10.96.0.10:53

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

rm -rf /run/flannel/*
cat <<EOF > /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF

uid=$(id -u u7s-admin)
socket="unix:///run/user/$uid/usernetes/crio/crio.sock"

kubelet \
	--cert-dir /etc/kubernetes/pki \
	--root-dir $XDG_DATA_HOME/usernetes/kubelet \
	--bootstrap-kubeconfig "/etc/kubernetes/bootstrap-kubelet.conf" \
	--kubeconfig "/etc/kubernetes/kubelet.conf" \
	--config $kubelet_config \
	--container-runtime-endpoint=$socket \
	--pod-infra-container-image=registry.local/k8s-p10/pause:3.9 \
	$@
