#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh

# set -x
# logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
# echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

extIP=$1
cmd=$2
shift;shift
pars=$*
case $cmd in
  init)
    if [ "$#" -gt 0 ]
    then
      echo -ne "Лишние параметры $*\nФормат вызова: \n$0 init\n";
      exit
    fi
    ;;
  join)
    apiServer=$1
    if [ $# -eq 0 ]
    then
      echo -ne "Отсутствуют параметры\nФормат вызова: \n$0 init|join <параметры>\n";
      exit 1
    fi
  ;;
  *)
    echo -ne "Формат вызова: \n$0 init|join <параметры>\n";
    exit 1;
esac

# Чистим старые сертификаты
rm -rf /var/lib/u7s-admin/usernetes/var/lib/etcd
mkdir -p /var/lib/u7s-admin/usernetes/var/lib/etcd

# Копируем coredns.yaml  kube-flannel.yml
cp /var/lib/u7s-admin/usernetes/manifests/* /etc/kubernetes/manifests/

uid=$(id -u u7s-admin)
mkdir -p /run/crio/

chown u7s-admin:u7s-admin /run/crio/
/bin/ln -sf /run/user/${uid}/usernetes/crio/crio.sock  /run/crio/crio.sock

configFile="$U7S_BASE_DIR/kubeadm-configs/$cmd.yaml"
host=$(hostname)
TMPFILE=$(mktemp "/tmp/kubeadm.XXXXXX")

if [ "$cmd" = 'init' ]
then
  if cat $configFile |
    yq -y 'select(.kind == "InitConfiguration").localAPIEndpoint.advertiseAddress |="'$extIP'"' |
    yq -y 'select(.kind == "ClusterConfiguration").controlPlaneEndpoint |="'$extIP'"' |
    yq -y 'select(.kind == "ClusterConfiguration").etcd.local.extraArgs."initial-cluster" |="'${host}=https://0.0.0.0:2380'"' |
    yq -y 'select(.kind == "ClusterConfiguration").etcd.local.extraArgs.name |= "'$host'"' \
    > $TMPFILE
  then
    mv $TMPFILE $configFile
  else
    echo "Не удалось установить внешний API-адрес $extIP в файл конфигурации kubeadm" >&2
  fi

else
  if cat $configFile |
    yq -y  'select(.kind == "JoinConfiguration").discovery.bootstrapToken.apiServerEndpoint |= "'$apiServer'"' | \
    yq -y  'select(.kind == "JoinConfiguration").nodeRegistration.name |= "'$host'"'
      > $TMPFILE
  then
    mv $TMPFILE $configFile
  else
    echo "Не удалось установить внешний API-адрес $extIP в файл конфигурации kubeadm" >&2
  fi
fi

/usr/bin/kubeadm $cmd \
  -v 9 \
  $parss \
  --config $configFile
