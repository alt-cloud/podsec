#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1
clustername=`kubectl config  view -o jsonpath='{.clusters[0].name}'`
clusterapi=`kubectl config  view -o jsonpath='{.clusters[0].cluster.server}'`

kubectl config set-cluster $clustername --certificate-authority=ca.crt --embed-certs=true --server=$clusterapi --kubeconfig=config
kubectl config set-credentials $user --client-certificate=$user.crt --client-key=$user.key --embed-certs=true --kubeconfig=config
kubectl config set-context default --cluster=$clustername --user=$user --kubeconfig=config
kubectl config use-context default --kubeconfig=config
