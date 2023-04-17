#!/bin/bash
set -x
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

rk_state_dir=$XDG_RUNTIME_DIR/usernetes/rootlesskit
if [[ -n $U7S_ROOTLESSKIT_PORTS ]]
then
  rootlessctl --socket $rk_state_dir/api.sock add-ports $U7S_ROOTLESSKIT_PORTS
fi

cmd=$(basename $0)
exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/$cmd $@

# cmd=$(yq '.spec.containers[0].command | join(" ")' /etc/kubernetes/manifests/kube-apiserver.yaml)
#
# eval  $(setEnvsByYaml /etc/kubernetes/manifests/kube-apiserver.yaml)
# cmd+=" --kubelet-certificate-authority=$lient_ca_file "

# exec $(dirname $0)/nsenter.sh kube-apiserver \
# 	--authorization-mode=RBAC \
# 	--etcd-cafile=$XDG_CONFIG_HOME/usernetes/master/ca.pem \
# 	--etcd-certfile=$XDG_CONFIG_HOME/usernetes/master/kubernetes.pem \
# 	--etcd-keyfile=$XDG_CONFIG_HOME/usernetes/master/kubernetes-key.pem \
# 	--etcd-servers https://127.0.0.1:2379 \
# 	--client-ca-file=$XDG_CONFIG_HOME/usernetes/master/ca.pem \
# 	--kubelet-certificate-authority=$XDG_CONFIG_HOME/usernetes/master/ca.pem \
# 	--kubelet-client-certificate=$XDG_CONFIG_HOME/usernetes/master/kubernetes.pem \
# 	--kubelet-client-key=$XDG_CONFIG_HOME/usernetes/master/kubernetes-key.pem \
# 	--tls-cert-file=$XDG_CONFIG_HOME/usernetes/master/kubernetes.pem \
# 	--tls-private-key-file=$XDG_CONFIG_HOME/usernetes/master/kubernetes-key.pem \
# 	--service-account-key-file=$XDG_CONFIG_HOME/usernetes/master/service-account.pem \
# 	--service-cluster-ip-range=10.0.0.0/24 \
# 	--service-account-issuer="kubernetes.default.svc" \
# 	--service-account-signing-key-file=$XDG_CONFIG_HOME/usernetes/master/service-account-key.pem \
# 	--advertise-address=$(cat $XDG_RUNTIME_DIR/usernetes/parent_ip) \
# 	--allow-privileged \
# 	$@

# TODO: enable --authorization-mode=Node,RBAC \
