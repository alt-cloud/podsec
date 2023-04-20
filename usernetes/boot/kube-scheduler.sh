#!/bin/bash
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

set -x
logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2


uid=$(id -u)
echo "$0: uid=$uid"

if [ $uid -eq 0 ]
then
	exec $U7S_BASE_DIR/bin/_kube-scheduler.sh $@
else
	exec $(dirname $0)/nsenter.sh $U7S_BASE_DIR/bin/_kube-scheduler.sh $@
fi
