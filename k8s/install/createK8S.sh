#!/bin/sh

if [ $# -ne 1 ]
then
  echo -ne "Формат:\n\t $0 <adminUser>\n"
  exit 1
fi

user=$1

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
group=$(id -g -n)
chown -R $user:$group .kubechown -R $user:$user .kube
chmod -R 0700 .kube

#!/bin/sh

if [ ! -f "/etc/kubernetes/audit/policy.yaml" ]
then
  mkdir /etc/kubernetes/audit
  cat <<EOF > /etc/kubernetes/audit/policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:

- level: None
  verbs: ["get", "watch", "list"]

- level: None
  resources:
  - group: "" # core
    resources: ["events"]

- level: None
  users:
  - "system:kube-scheduler"
  - "system:kube-proxy"
  - "system:apiserver"
  - "system:kube-controller-manager"
  - "system:serviceaccount:gatekeeper-system:gatekeeper-admin"

- level: None
  userGroups: ["system:nodes"]

- level: RequestResponse
EOF
fi

# Настройка аудита API-сервиса kubernetes
haveAudit=$(cat /etc/kubernetes/manifests/kube-apiserver.yaml   | yq  '[.spec.volumes[].hostPath][].path | select(. == "/etc/kubernetes/audit")')
if [ -z "$haveAudit" ]
then
  TMPFILE="/tmp/kube-api-server.$$"
  confFile="/etc/kubernetes/manifests/kube-apiserver.yaml"
  cat $confFile |
  yq -y  '.spec.containers[].command |= . +
  ["--audit-policy-file=/etc/kubernetes/audit/policy.yaml"] +
  ["--audit-log-path=/etc/kubernetes/audit/audit.log"] +
  ["--audit-log-maxsize=500"] +
  ["--audit-log-maxbackup=3"]
  ' |
  yq -y  '.spec.containers[].volumeMounts |= . +
  [{ "mountPath": "/etc/kubernetes/audit", "name": "audit" }]
  ' |
  yq -y '.spec.volumes |= . +
  [{ "hostPath": {"path": "/etc/kubernetes/audit" , "type": "DirectoryOrCreate" }, "name": "audit" }]
  ' > $TMPFILE
  if [ -s $TMPFILE ]
  then
    mv $TMPFILE $confFile
  fi
fi

# Обеспечение доступа по root
echo “PermitRootLogin yes” >> /etc/openssh/sshd_config
systemctl restart sshd

