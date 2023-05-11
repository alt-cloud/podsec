#!/bin/sh

logger  "=============================================== KUBEADM ====================================="

source podsec-u7s-functions

envDir=$(dirname $envFile)
mkdir -p $envDir
cp /etc/podsec/u7s/config/env $envFile

source $envFile

# set -x
cmd=$1

# На новом ядре 6.1 почему то иногда пропадает /run/crio/crio.sock, возможно не успевает стартовать сервис rootlesskit
until [ -S /run/user/${U7S_UID}/usernetes/crio/crio.sock ]
do
  /sbin/systemctl --user -T stop rootlesskit.service
  sleep 1
  /sbin/systemctl --user -T start rootlesskit.service
  sleep 3
done

nsenter_u7s _kubeadm.sh "$cmd"


