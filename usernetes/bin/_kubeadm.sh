#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
# set -x
source ~u7s-admin/.config/usernetes/env

logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

extIP=$1
cmd=$2

if [ $U7S_CONTROLPLANE = 'initMaster' ]
then
  # Создаем каталог базы etcd
  rm -rf /var/lib/u7s-admin/usernetes/var/lib/etcd
  mkdir -p /var/lib/u7s-admin/usernetes/var/lib/etcd
fi

# Копируем coredns.yaml  kube-flannel.yml
cp /var/lib/u7s-admin/usernetes/manifests/* /etc/kubernetes/manifests/

uid=$(id -u u7s-admin)
mkdir -p /run/crio/

chown u7s-admin:u7s-admin /run/crio/
/bin/ln -sf /run/user/${uid}/usernetes/crio/crio.sock  /run/crio/crio.sock

srcConfigFile="$U7S_BASE_DIR/kubeadm-configs/$cmd.yaml"
configFile="/tmp/$cmd.yaml"
host=$(hostname)
TMPFILE=$(mktemp "/tmp/kubeadm.XXXXXX")

if [ "$cmd" = 'init' ]
then
  if cat $srcConfigFile |
    yq -y 'select(.kind == "InitConfiguration").localAPIEndpoint.advertiseAddress |="'$extIP'"' |
    yq -y 'select(.kind == "ClusterConfiguration").controlPlaneEndpoint |="'$extIP'"' |
    yq -y 'select(.kind == "ClusterConfiguration").etcd.local.extraArgs."initial-cluster" |="'${host}=https://0.0.0.0:2380'"' |
    yq -y 'select(.kind == "ClusterConfiguration").etcd.local.extraArgs.name |= "'$host'"' \
    > $configFile
  then
    :;
  else
    echo "Не удалось установить внешний API-адрес $extIP в файл конфигурации kubeadm" >&2
  fi
else
  if cat $srcConfigFile |
    yq -y '
      select(.kind == "JoinConfiguration").discovery.bootstrapToken.token |= "'$U7S_TOKEN'" |
      select(.kind == "JoinConfiguration").discovery.bootstrapToken.caCertHashes |= ["'$U7S_CACERTHASH'"]' |
    yq -y  'select(.kind == "JoinConfiguration").discovery.bootstrapToken.apiServerEndpoint |= "'$U7S_APISERVER'"' |
    yq -y  'select(.kind == "JoinConfiguration").nodeRegistration.name |= "'$host'"' > $configFile
  then
    :;
  else
    echo "Не удалось установить внешний API-адрес $extIP в файл конфигурации kubeadm" >&2
  fi
  if [ -n "$controlPlane" ]
  then
    if cat $configFile |
      yq -y 'select(.kind == "JoinConfiguration").controlPlane.localAPIEndpoint.advertiseAddress |= "'$extIP'"' > $TMPFILE
    then
      mv $TMPFILE $configFile
    else
      echo "Не удалось установить внешний API-адрес $extIP в файл конфигурации kubeadm" >&2
    fi
  fi
fi
# echo "CONFIGFILE="; cat $configFile

/usr/bin/kubeadm $cmd \
  -v $U7S_DEBUGLEVEL \
  --config $configFile
