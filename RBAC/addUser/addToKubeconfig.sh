#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1
kubectl config set-credentials $user --client-key=$user.key --client-certificate=$user.crt --embed-certs=true
kubectl config set-context $user --cluster=kubernetes --user=$user
