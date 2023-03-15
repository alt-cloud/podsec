#!/bin/sh

. podsec-functions

notInstalled=$(testPackages kubernetes-kubeadm kubernetes-kubelet kubernetes-crio cri-tools skopeo)

if [ -n "$notInstalled" ]
then
  echo "Пакеты $notInstalled  не установлены"
  exit 1
fi

if [ $# -ne 1 ]
then
  echo -ne "Формат:\n\t $0 <adminUser>\n"
  exit 1
fi

user=$1

if ! grep  '^pause_image' /etc/crio/crio.conf
then
  cat <<EOF >>/etc/crio/crio.conf
[crio.image]
pause_image = "registry.local/k8s-p10/pause:3.7"
EOF
fi


. /etc/kubernetes/kubelet
if ! (echo $KUBELET_ARGS | grep pod-infra-container-image)
then
  KUBELET_ARGS+=' --pod-infra-container-image=registry.local/k8s-p10/pause:3.7'
  sed -i -e "s|KUBELET_ARGS.*|KUBELET_ARGS=\"$KUBELET_ARGS\"|" /etc/kubernetes/kubelet
fi
systemctl enable --now crio kubelet

kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.24.8 --image-repository=registry.local

mkdir /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod -R 600 /root/.kube
pwd=$PWD
su -c "kubectl apply -f $pwd/kube-flannel.yml"

cd $user
cp -r /root/.kube .
chmod -R 600 .kube
chown -R $user:podman .kube
