#!/bin/sh

if [ $# -le 1 ]
then
  echo "Не указан каталог архивирования образов"
  echo -ne "Формат:\n\t$0 <каталог_архивирования_образов><архитектура>,<архитектура>,...|all\n"
  exit 1
fi

if [ $# -ne 2 ]
then
  echo "Не указан список архитектур"
  echo -ne "Формат:\n\t$0 <каталог_архивирования_образов> <архитектура>,<архитектура>,...|all\n"
  exit 1
fi

ociDir=$1
archs=$2

imagesList='
coredns:v1.8.6
kube-controller-manager:v1.24.8
kube-apiserver:v1.24.8
kube-proxy:v1.24.8
etcd:3.5.5-0
flannel:v0.19.2
kube-scheduler:v1.24.8
pause:3.7
flannel-cni-plugin:v1.2.0
cert-manager-controller:v1.9.1
cert-manager-cainjector:v1.9.1
cert-manager-webhook:v1.9.1
'

saveOci.sh $ociDir $archs $imagesList
