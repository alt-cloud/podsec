#!/bin/sh

if [ $# -ne 1 ]
then
  echo -ne "Формат:\n\t $0 <adminUser>\n"
  exit 1
fi

user=$1

# Настройка /etc/crio/crio.conf на использования в качестве образа pause registry.local/k8s-p10/pause:3.7
echo "Настройка /etc/crio/crio.conf на использования в качестве образа pause registry.local/k8s-p10/pause:3.7"
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

# Запуск серввиса kubelet
echo "Запуск серввиса kubelet"
systemctl enable --now crio kubelet

# Инициализация master-узла кластера
echo "Инициализация master-узла кластера"
kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.24.8 --image-repository=registry.local/k8s-p10

# Настройка root на роль администратора кластера
echo "Настройка root на роль администратора кластера"
mkdir /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod -R 600 /root/.kube
pwd=$PWD
su -c "kubectl apply -f /etc/kubernetes/manifests/kube-flannel.yml"

# Настройка $user на роль администратора кластера
echo "Настройка $user на роль администратора кластера"
cd /home/$user
mkdir .kube
cp /etc/kubernetes/admin.conf .kube/config
chown -R $user:$user .kubechown -R $user:$user .kube
chmod -R 0700 .kube
