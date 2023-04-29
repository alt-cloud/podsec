#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

set -x
logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

: ${U7S_FLANNEL=}

parent_ip=$(cat $XDG_RUNTIME_DIR/usernetes/parent_ip)

pars='--iface "tap0" --ip-masq--public-ip "'$parent_ip'"'

if [ $U7S_CONTROLPLANE = 'master' ]
then
	eval  $(setEnvsByYaml /etc/kubernetes/manifests/etcd.yaml)
	pars+="	--etcd-endpoints $advertise_client_urls \
	--etcd-cafile $trusted_ca_file \
	--etcd-certfile $cert_file \
	--etcd-keyfile $key_file"
fi

exec flanneld $pars	$@
