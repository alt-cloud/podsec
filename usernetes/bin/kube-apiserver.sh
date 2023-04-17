#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

cmd=$(yq '.spec.containers[0].command | join(" ")' /etc/kubernetes/manifests/kube-apiserver.yaml)

eval  $(setEnvsByYaml /etc/kubernetes/manifests/kube-apiserver.yaml)
cmd+=" --kubelet-certificate-authority=$lient_ca_file "

$cmd $@
