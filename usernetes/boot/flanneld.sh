#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_flanneld.sh $@

# FIXME: nodes should not require the master key.
# Currently nodes require the master key because flanneld and master
# share the same etcd cluster.
