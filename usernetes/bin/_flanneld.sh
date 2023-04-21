#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

set -x
logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

: ${U7S_FLANNEL=}
if [[ $U7S_FLANNEL != 1 ]]; then
	log_error "U7S_FLANNEL needs to be 1"
	exit 1
fi

parent_ip=$(cat $XDG_RUNTIME_DIR/usernetes/parent_ip)

eval  $(setEnvsByYaml /etc/kubernetes/manifests/etcd.yaml)

exec flanneld \
	--iface "tap0" \
	--ip-masq \
	--public-ip "$parent_ip" \
	--etcd-endpoints $advertise_client_urls \
	--etcd-cafile $trusted_ca_file \
	--etcd-certfile $cert_file \
	--etcd-keyfile $key_file \
	$@
