#!/bin/bash
set -x
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

if [[ $U7S_FLANNEL == 1 ]];
then
	exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_etcd-init-data.sh $@
fi

# : ${U7S_FLANNEL=}
# eval  $(setEnvsByYaml /etc/kubernetes/manifests/etcd.yaml)
# if [[ $U7S_FLANNEL == 1 ]]; then
# 	config=$U7S_BASE_DIR/config/flannel/etcd/coreos.com_network_config
# # 	set -x
# 	timeout 60 sh -c "until cat $config | ETCDCTL_API=3 etcdctl --endpoints $advertise_client_urls --cacert=$peer_trusted_ca_file --cert=$cert_file --key=$key_file put /coreos.com/network/config; do sleep 1; done"
# # 	timeout 60 sh -c "until cat $config | ETCDCTL_API=3 etcdctl --endpoints https://127.0.0.1:2379 --cacert=$XDG_CONFIG_HOME/usernetes/master/ca.pem --cert=$XDG_CONFIG_HOME/usernetes/master/kubernetes.pem --key=$XDG_CONFIG_HOME/usernetes/master/kubernetes-key.pem put /coreos.com/network/config; do sleep 1; done"
# fi
