#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
set -x
logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

TMPFILE=$(mktemp "/tmp/etcd.XXXXXX")
etcd_config="/etc/kubernetes/manifests/etcd.yaml"

etcDataDir="/var/lib/u7s-admin/usernetes/var/lib/etcd"
mkdir -p $etcDataDir
if cat $etcd_config |
#   yq '.spec.containers[0].command|= .+["--enable-v2=true", "--data-dir='$etcDataDir'"]' >$TMPFILE
  yq '.spec.containers[0].command|= .+["--enable-v2=true"]' >$TMPFILE
then
  mv $TMPFILE $etcd_config
else
  echo "Не удалось установить datadir в файл конфигурации etcd" >&2
fi

cmd=$(yq '.spec.containers[0].command | join(" ")' $etcd_config)
cmd=${cmd:1:-1}

/usr/sbin/$cmd $@
