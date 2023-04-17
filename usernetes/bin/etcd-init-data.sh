#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
: ${U7S_FLANNEL=}
set -x

eval  $(setEnvsByYaml /etc/kubernetes/manifests/etcd.yaml)
config=$U7S_BASE_DIR/config/flannel/etcd/coreos.com_network_config
timeout 60 sh -c "until cat $config | ETCDCTL_API=3 etcdctl --endpoints $advertise_client_urls --cacert=$peer_trusted_ca_file --cert=$cert_file --key=$key_file put /coreos.com/network/config; do sleep 1; done"
