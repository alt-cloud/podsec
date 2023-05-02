#!/bin/sh
export U7S_BASE_DIR=$(realpath $(dirname $0)/..)
source $U7S_BASE_DIR/common/common.inc.sh
# set -x
source ~u7s-admin/.config/usernetes/env

logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

# extIP=$1
cmd=$1

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

# srcConfigFile="$U7S_BASE_DIR/kubeadm-configs/$cmd.yaml"
configFile="$U7S_BASE_DIR/kubeadm-configs/$cmd.yaml"
host=$(hostname)
TMPFILE=$(mktemp "/tmp/kubeadm.XXXXXX")

(
if [ "$cmd" = 'init' ]
then
  yq -y '.localAPIEndpoint.advertiseAddress |="'$U7S_EXTIP'"' < $U7S_BASE_DIR/kubeadm-configs/InitConfiguration.yaml
else
   yq -y '.discovery.bootstrapToken.token |= "'$U7S_TOKEN'" |
          .discovery.bootstrapToken.caCertHashes |= ["'$U7S_CACERTHASH'"] |
          .discovery.bootstrapToken.apiServerEndpoint |= "'$U7S_APISERVER'" |
          .nodeRegistration.name |= "'$host'"
         '  < $U7S_BASE_DIR/kubeadm-configs/JoinConfiguration.yaml
fi
echo "---"
if [ -n "$U7S_CONTROLPLANE" ]
then
  yq -y '.controlPlaneEndpoint |="'$U7S_EXTIP'" |
         .etcd.local.extraArgs."initial-cluster" |="'${host}=https://0.0.0.0:2380'" |
         .etcd.local.extraArgs.name |= "'$host'" |
         .etcd.local.serverCertSANs |= ["'$U7S_TAPIP'", "127.0.0.1"] |
         .etcd.local.peerCertSANs |= ["'$U7S_TAPIP'"] |
         .apiServer.extraArgs."advertise-address"="'$U7S_TAPIP'" |
         .controlPlaneEndpoint = "'${U7S_EXTIP}':6443"
        ' < $U7S_BASE_DIR/kubeadm-configs/ClusterConfigurationWithEtcd.yaml
  echo "---"
fi
cat $U7S_BASE_DIR/kubeadm-configs/KubeletConfiguration.yaml
echo "---"
cat $U7S_BASE_DIR/kubeadm-configs/KubeProxyConfiguration.yaml
) > $configFile

# if [ "$cmd" = 'init' ]
# then
#   if cat $U7S_BASE_DIR/kubeadm-configs/init.yaml |
#     yq -y 'select(.kind == "InitConfiguration").localAPIEndpoint.advertiseAddress |="'$extIP'"' |
#     yq -y 'select(.kind == "ClusterConfiguration").controlPlaneEndpoint |="'$extIP'"' |
#     yq -y 'select(.kind == "ClusterConfiguration").etcd.local.extraArgs."initial-cluster" |="'${host}=https://0.0.0.0:2380'"' |
#     yq -y 'select(.kind == "ClusterConfiguration").etcd.local.extraArgs.name |= "'$host'"' \
#     > $configFile
#   then
#     :;
#   else
#     echo "Не удалось установить внешний API-адрес $extIP в файл конфигурации kubeadm" >&2
#     exit 1
#   fi
# else
#   if [ "$cmd" != 'join' ]
#   then
#     echo "Незвестная kubeadm подкоманда $cmd" >&2
#     exit 1
#   fi
#   if [ $U7S_CONTROLPLANE = 'master' ] # JOIN CONTROLPLANE
#   then
#     if cat $U7S_BASE_DIR/kubeadm-configs/joinControlPlane.yaml |
#     yq -y '.' > $configFile
#   else  # JOIN WORKER
#     if cat $U7S_BASE_DIR/kubeadm-configs/join.yaml |
#       yq -y '
#         select(.kind == "JoinConfiguration").discovery.bootstrapToken.token |= "'$U7S_TOKEN'" |
#         select(.kind == "JoinConfiguration").discovery.bootstrapToken.caCertHashes |= ["'$U7S_CACERTHASH'"]' |
#       yq -y  'select(.kind == "JoinConfiguration").discovery.bootstrapToken.apiServerEndpoint |= "'$U7S_APISERVER'"' |
#       yq -y  'select(.kind == "JoinConfiguration").nodeRegistration.name |= "'$host'"' > $configFile
#     then
#       :;
#     else
#       echo "Не удалось установить внешний API-адрес $extIP в файл конфигурации kubeadm" >&2
#     fi
#   fi
# fi
echo "CONFIGFILE="; cat $configFile

/usr/bin/kubeadm $cmd \
  -v $U7S_DEBUGLEVEL \
  --config $configFile
