#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
set -x
exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_etcd.sh $@

# cmd=$(yq '.spec.containers[0].command | join(" ")' /etc/kubernetes/manifests/etcd.yaml)
# cmd+=" --enable-v2=true "

# FIXME: no need to nsenter?
# exec $(dirname $0)/nsenter.sh $cmd $@
# 	etcd \
# 	--data-dir $XDG_DATA_HOME/usernetes/etcd \
# 	--enable-v2=true \
# 	--name $(hostname -s) \
# 	--cert-file=$XDG_CONFIG_HOME/usernetes/pki/etcd/server.crt \
# 	--key-file=$XDG_CONFIG_HOME/usernetes/pki/etcd/server.key \
# 	--peer-cert-file=$XDG_CONFIG_HOME/usernetespki/etcd/server.crt \
# 	--peer-key-file=$XDG_CONFIG_HOME/usernetes/pki/etcd/server.key \
# 	--trusted-ca-file=$XDG_CONFIG_HOME/usernetes/master/ca.pem \
# 	--peer-trusted-ca-file=$XDG_CONFIG_HOME/usernetes/master/ca.pem \
# 	--peer-client-cert-auth \
# 	--client-cert-auth \
# 	--listen-client-urls https://0.0.0.0:2379 \
# 	--listen-peer-urls https://0.0.0.0:2380 \
# 	--advertise-client-urls https://127.0.0.1:2379 \
# 	--initial-advertise-peer-urls https://127.0.0.1:2380 \
# 	$@
