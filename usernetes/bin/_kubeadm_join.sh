#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

# set -x
# logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
# echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

extIP=$1
shift
params=$*

# Чистим старые сертифиаты
rm -rf /var/lib/u7s-admin/usernetes/var/lib/etcd
mkdir -p /var/lib/u7s-admin/usernetes/var/lib/etcd

# Копируем coredns.yaml  kube-flannel.yml
cp /var/lib/u7s-admin/usernetes/manifests/* /etc/kubernetes/manifests/

uid=$(id -u u7s-admin)

configFile="$U7S_BASE_DIR/kubeadm-configs/join.yaml"
TMPFILE=$(mktemp "/tmp/kubeadm.XXXXXX")
host=$(hostname)

# if cat $configFile |
#   yq -y 'select(.kind == "InitConfiguration").localAPIEndpoint.advertiseAddress |="'$extIP'"' |
#   yq -y 'select(.kind == "ClusterConfiguration").controlPlaneEndpoint |="'$extIP'"' |
#   yq -y 'select(.kind == "ClusterConfiguration").etcd.local.extraArgs."initial-cluster" |="'${host}=https://0.0.0.0:2380'"' |
#   yq -y 'select(.kind == "ClusterConfiguration").etcd.local.extraArgs.name |= "'$host'"' \
#   > $TMPFILE
# then
#   mv $TMPFILE $configFile
# else
#   echo "Не удалось установить внешний API-адрес $extIP в файл конфигурации kubeadm" >&2
# fi

mkdir -p /run/crio/
chown u7s-admin:u7s-admin /run/crio/
/bin/ln -sf /run/user/${uid}/usernetes/crio/crio.sock  /run/crio/crio.sock

/usr/bin/kubeadm join \
   -v 9 \
   $params \
  --config $configFile
