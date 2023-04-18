#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
set -x
exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_kube-controller-manager.sh $@


# cmd=$(yq '.spec.containers[0].command | join(" ")' /etc/kubernetes/manifests/kube-controller-manager.yaml)
#
# exec $(dirname $0)/nsenter.sh $cmd $@

# exec $(dirname $0)/nsenter.sh kube-controller-manager \
# 	--cluster-name=kubernetes \
# 	--cluster-signing-cert-file=$XDG_CONFIG_HOME/usernetes/master/ca.pem \
# 	--cluster-signing-key-file=$XDG_CONFIG_HOME/usernetes/master/ca-key.pem \
# 	--kubeconfig=$XDG_CONFIG_HOME/usernetes/master/kube-controller-manager.kubeconfig \
# 	--root-ca-file=$XDG_CONFIG_HOME/usernetes/master/ca.pem \
# 	--service-account-private-key-file=$XDG_CONFIG_HOME/usernetes/master/service-account-key.pem \
# 	--use-service-account-credentials=true \
# 	$@
