#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1

clustername=`kubectl config  view -o jsonpath='{.clusters[0].name}'`
kubectl config set-credentials $user --client-certificate=$user.crt --client-key=$user.key --embed-certs=true 
kubectl config set-context $user --cluster=$clustername --user=$user 

