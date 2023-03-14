#!/bin/sh

if [ $# -ne 1 ]
then
  echo -ne "Формат:\n\t $0 <adminUser>"
  exit 1
fi

apt-get install kubernetes-kubeadm kubernetes-kubelet kubernetes-crio cri-tools

if ! grep  '^pause_image' /etc/crio/crio.conf
then
  cat <<EOF >>/etc/crio/crio.conf
[crio.image]
pause_image = "registry.local/k8s-p10/pause:3.7"
EOF
fi

. /etc/kubernetes/kubelet
KUBELET_ARGS+=' --pod-infra-container-image=registry.local/k8s-p10/pause:3.7'
sed -i -e "s|KUBELET_ARGS.*|KUBELET_ARGS=\"$KUBELET_ARGS\"|" /etc/kubernetes/kubelet
systemctl enable --now crio kubelet

kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.24.8 --image-repository=registry.local/k8s-p10

mkdir /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod -R 600 /root/.kube

cd $user
cp -r /root/.kube .
chmod -R 600 .kube
chown -R $user:podman .kube

kubectl apply -f kube-flannel.yml
