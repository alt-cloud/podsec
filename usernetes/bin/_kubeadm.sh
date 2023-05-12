#!/bin/sh
source podsec-u7s-functions
# set -x
source $envFile

logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

# extIP=$1
cmd=$1

if [ "$U7S_CONTROLPLANE" = 'initMaster' ]
then
  # Создаем каталог базы etcd
  rm -rf /var/lib/Etcd
  mkdir -p /var/lib/Etcd
fi

# Копируем coredns.yaml  kube-flannel.yml
# cp /etc/podsec/u7s/config/manifests/* /etc/kubernetes/manifests/

uid=$(id -u u7s-admin)

mkdir -p /run/crio/
chown u7s-admin:u7s-admin /run/crio/
/bin/ln -sf /run/user/${uid}/usernetes/crio/crio.sock  /run/crio/crio.sock

KUBEADM_CONFIGS_DIR=/etc/podsec/u7s/config/kubeadm-configs
configFile="$XDG_CONFIG_HOME/usernetes/$cmd.yaml"
host=$(hostname)
TMPFILE=$(mktemp "/tmp/kubeadm.XXXXXX")

(
if [ "$cmd" = 'init' ]
then
  yq -y '.localAPIEndpoint.advertiseAddress |="'$U7S_EXTIP'"' $KUBEADM_CONFIGS_DIR/InitConfiguration.yaml
else
  if [ -n "$U7S_CONTROLPLANE" ]
  then
    yq -y '
          .discovery.bootstrapToken.token |= "'$U7S_TOKEN'" |
          .discovery.bootstrapToken.caCertHashes |= ["'$U7S_CACERTHASH'"] |
          .discovery.bootstrapToken.apiServerEndpoint |= "'$U7S_APISERVER'" |
          .nodeRegistration.name |= "'$host'" |
          .controlPlane.localAPIEndpoint.advertiseAddress |="'$U7S_EXTIP'"
          ' $KUBEADM_CONFIGS_DIR/JoinControlPlaneConfijuration.yaml
  else
   yq -y '
          .discovery.bootstrapToken.token |= "'$U7S_TOKEN'" |
          .discovery.bootstrapToken.caCertHashes |= ["'$U7S_CACERTHASH'"] |
          .discovery.bootstrapToken.apiServerEndpoint |= "'$U7S_APISERVER'" |
          .nodeRegistration.name |= "'$host'"
         ' $KUBEADM_CONFIGS_DIR/JoinConfiguration.yaml
  fi
fi
echo "---"
if [ -n "$U7S_CONTROLPLANE" ]
then
  yq -y '.controlPlaneEndpoint |="'$U7S_EXTIP'" |
         .etcd.local.extraArgs."initial-cluster" |="'${host}=https://0.0.0.0:2380'" |
         .etcd.local.extraArgs.name |= "'$host'" |
         .etcd.local.serverCertSANs |= ["'$U7S_EXTIP'","'$U7S_TAPIP'", "127.0.0.1"] |
         .etcd.local.peerCertSANs |= ["'$U7S_EXTIP'"] |
         .apiServer.extraArgs."advertise-address"="'$U7S_EXTIP'" |
         .controlPlaneEndpoint = "'${U7S_APISERVER}'"
        ' $KUBEADM_CONFIGS_DIR/ClusterConfigurationWithEtcd.yaml
  echo "---"
fi
cat $KUBEADM_CONFIGS_DIR/KubeletConfiguration.yaml
# yq -y '.address="'$U7S_TAPIP'"' < $KUBEADM_CONFIGS_DIR/KubeletConfiguration.yaml
echo "---"
cat $KUBEADM_CONFIGS_DIR/KubeProxyConfiguration.yaml
# yq -y '.bindAddress="'$U7S_TAPIP'"' < $KUBEADM_CONFIGS_DIR/KubeProxyConfiguration.yaml
) > $configFile


/usr/bin/kubeadm $cmd \
  -v $U7S_DEBUGLEVEL \
  --config $configFile
