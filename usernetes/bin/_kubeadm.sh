#!/bin/sh
source podsec-u7s-functions
# set -x
source $envFile

logger -- "`(echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*")`"
echo -ne "$0: TIME=$(date  +%H:%M:%S.%N) UID=$UID PID=$(cat $XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid) PARS=$*\n" >&2

# extIP=$1
cmd=$1

uid=$(id -u u7s-admin)

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
          .controlPlane.localAPIEndpoint.advertiseAddress |="'$U7S_EXTIP'" |
          .controlPlane.certificateKey |= "'$U7S_CERIFICATEKEY'"
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
  if [ "$U7S_CONTROLPLANE" =  'initMaster' ]
  then
    yq -y '.controlPlaneEndpoint |="'$U7S_EXTIP'" |
          .kubernetesVersion |= "'${U7S_KUBEVERSION:1}'" |
         .imageRepository|="'$U7S_REGISTRY_PLATFORM'" |
         .etcd.local.imageRepository|="'$U7S_REGISTRY_PLATFORM'" |
         .etcd.local.serverCertSANs |= ["'$U7S_EXTIP'", "127.0.0.1"] |
         .etcd.local.peerCertSANs |= ["'$U7S_EXTIP'"] |
         .apiServer.extraArgs."advertise-address"="'$U7S_EXTIP'" |
         .controllerManager.extraArgs."cluster-cidr" |= "'$U7S_PODNETWORKCIDR'" |
         .controllerManager.extraArgs."service-cluster-ip-range" |= "'$U7S_SERVICECIDR'" |
         .networking.podSubnet |= "'$U7S_PODNETWORKCIDR'" |
         .networking.serviceSubnet |= "'$U7S_SERVICECIDR'" |
         .controlPlaneEndpoint = "'${U7S_APISERVER}'"
        ' $KUBEADM_CONFIGS_DIR/InitClusterConfiguration.yaml
  else
    yq -y '.controlPlaneEndpoint |="'$U7S_EXTIP'" |
          .kubernetesVersion |= "'${U7S_KUBEVERSION:1}'" |
         .imageRepository|="'$U7S_REGISTRY_PLATFORM'" |
         .etcd.local.imageRepository|="'$U7S_REGISTRY_PLATFORM'" |
         .etcd.local.serverCertSANs |= ["'$U7S_EXTIP'", "127.0.0.1"] |
         .etcd.local.peerCertSANs |= ["'$U7S_EXTIP'"] |
         .apiServer.extraArgs."advertise-address"="'$U7S_EXTIP'" |
         .controllerManager.extraArgs."cluster-cidr" |= "'$U7S_PODNETWORKCIDR'" |
         .controllerManager.extraArgs."service-cluster-ip-range" |= "'$U7S_SERVICECIDR'" |
         .networking.podSubnet |= "'$U7S_PODNETWORKCIDR'" |
         .networking.serviceSubnet |= "'$U7S_SERVICECIDR'" |
         .controlPlaneEndpoint = "'${U7S_APISERVER}'"
        ' $KUBEADM_CONFIGS_DIR/JoinClusterConfiguration.yaml
  fi

  echo "---"
fi
cat $KUBEADM_CONFIGS_DIR/KubeletConfiguration.yaml
echo "---"
cat $KUBEADM_CONFIGS_DIR/KubeProxyConfiguration.yaml
) > $configFile

mkdir -p /run/crio/ || :;
/bin/ln -sf /run/user/${uid}/usernetes/crio/crio.sock  /run/crio/crio.sock || :;


if [ $cmd = 'init' ]
then
  U7S_KUBEADMFLAGS='--upload-certs'
fi

/usr/bin/kubeadm $cmd \
   $U7S_KUBEADMFLAGS \
  --config $configFile
