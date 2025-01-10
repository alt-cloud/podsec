#!/bin/sh

source podsec-k8s-upgrade-functions

export TEXTDOMAINDIR='/usr/share/locale'
export TEXTDOMAIN='podsec-k8s-upgrade'

source /var/lib/u7s-admin/.config/usernetes/env

export U7S_HOSTNAME=$(hostname)
export kubeVersion=$(getCurrentKubeAPIVersion)
export U7S_PLATFORM=$(getPlatform)
export U7S_REGISTRY=$(getRegistry)
export U7S_REGISTRYPATH="$U7S_REGISTRY/$U7S_PLATFORM"
export currentFlannelVersion=$(getCurrentFlannelVersion)
export U7S_IMAGES=$(/usr/bin/kubeadm config images list --image-repository=$U7S_REGISTRYPATH)
PAUSE_IMAGE=$(echo $U7S_IMAGES | tr ' ' '\n'  | grep /pause)
PAUSE_IMAGE=$(basename $PAUSE_IMAGE)
export U7S_PAUSE_IMAGE="$U7S_PLATFORM/$PAUSE_IMAGE"
export U7S_UID=${U7S_UID}
U7S_APISERVERURL=$(yq -r  '.clusters[0].cluster.server' /etc/kubernetes/admin.conf)
U7S_APISERVERENDPOINT=${U7S_APISERVERURL:8}
ifs=$IFS; IFS=:; set -- $U7S_APISERVERENDPOINT; IFS=$ifs;
U7S_APISERVER_ADVERTISE_ADDRESS=$1
U7S_APISERVER_BIND_PORT=$2

echo "
U7S_KUBEVERSION='v${kubeVersion}'
U7S_KUBEADMFLAGS=''
U7S_PLATFORM='${U7S_PLATFORM}'
U7S_ALTREGISTRY='registry.altlinux.org'
U7S_REGISTRY='${U7S_REGISTRY}'
U7S_FLANNEL_REGISTRY='${U7S_REGISTRY}'
U7S_FLANNEL_TAG='v${currentFlannelVersion}'
U7S_REGISTRY_PLATFORM='${U7S_REGISTRYPATH}'
U7S_IMAGES='$U7S_IMAGES'
U7S_CNI_PLUGIN='flannel'
U7S_SKIP_PHASES=''
U7S_PAUSE_IMAGE='$U7S_PAUSE_IMAGE'
U7S_APISERVERENDPOINT=${U7S_APISERVERENDPOINT}
U7S_APISERVER_ADVERTISE_ADDRESS='${U7S_APISERVER_ADVERTISE_ADDRESS}'
U7S_APISERVER_BIND_PORT='${U7S_APISERVER_BIND_PORT}'
_CONTAINERS_ROOTLESS_UID='${U7S_UID}'
_CONTAINERS_USERNS_CONFIGURED=1
" >> /var/lib/u7s-admin/.config/usernetes/env

# exit
mount /media/ALTLinux/
apt-cdrom add
apt-repo add 'rpm cdrom:[ALT SP Server 10.2 11100-01 x86_64 build 2024-11-07]/ ALTLinux main'
apt-repo rm 'rpm http://sigstore.local:81/kubernetes_upgrade x86_64 main'
apt-repo rm 'rpm cdrom:[ALT SP Server 11100-01 x86_64 build 2023-05-29]/ ALTLinux main'
apt-get update
<<<<<<< HEAD
systemctl stop u7s
rpm -e --nodeps flannel
rpm -e --nodeps cni-plugin-flannel
chown u7s-admin:u7s-admin /etc/cni/net.d/
apt-get -y dist-upgrade --fix-broken
control newuidmap public
control newgidmap public
systemctl start u7s
=======
systectl stop u7s
apt-get -y dist-upgrade
control newuidmap public
control newgidmap public
>>>>>>> 14b80c7 (The functions have been moved to the script podsec-k8s-upgrade-functions and script podsec-k8s-upgrade-podsec.sh has been added to upgrade c10f1 to c10f2)
