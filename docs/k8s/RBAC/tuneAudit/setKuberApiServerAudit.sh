#!/bin/sh 
# Скрипт формирует файл  etc/kubernetes/audit/policy.yaml 
# и модифицирует файл /kubernetes/manifests/kube-apiserver.yaml запуска kube-apiserver 
# для настройки аудита 

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
