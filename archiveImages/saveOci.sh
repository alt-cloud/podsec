#!/bin/sh
# Скрипт производит архивацию образов kubernetes версии 1.24.8
# в указанный первым параметром каталог
# остальные параметры задают архивируемые архитектуры, если отсутствуют архивируются все архитектуры amd64 arm64 arm ppc64le 386
# Скрипт производит загрузку kubernet-образов с регистратора registry.altlinux.org/k8s-p10 в containers-storage: системы
# с последующим помещением их в указанный первым параметром каталог в подкаталог с именем архитектуры ($ociDir/$arch)
# для улучшения последующей компресии слои образа помещаются несжатыми (параметр --dest-oci-accept-uncompressed-layers)
# После окончания наполнения подкаталога архитектуры он архивируется, сжимается и помещается в файл $ociDir/$arch.tar.xz
#
# Так как скрипт производит загрузку образов различных архитектур
# последняя загруженная в containers-storage: архитектура может отличаться от текущей архитектуры процессора
# При необходимости нужно будет произвести перезагрузку образов для рабочей архитектуры процессора

ociDir=$1
shift
# arch=$2

if [ -d $ociDir ]
then
  echo "OCI-каталог уже существует"
  exit 1
fi
mkdir $ociDir

regName='registry.altlinux.org/k8s-p10'

baseImagesList='
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
'

addImagesList='
cert-manager-cainjector:v1.9.1
cert-manager-webhook:v1.9.1
'

if [ $# -gt 0 ]
then
  for arch
  do
    case $1 in
      amd64 | arm64 | arm | ppc64le | 386) :;;
      *)
        echo "Неизвестная архитектура $arch";
        echo "Допустимые: amd64, arm64, arm, ppc64le, 386"
        echo -ne "Формат:\n\t$0 каталог_разворачивания_врхивов [архитектура ...]\n"
    esac
  done
else
  set -- arm64 arm ppc64le 386 amd64
fi

for arch
do
  echo $arch
  ociArchDir="$ociDir/$arch"
  if [ -d $ociArchDir ]
  then
    mkdir $ociArchDir
  fi
  for image in $baseImagesList
  do
    echo "  image=$image"
    Image="$regName/$image"
    skopeo --override-arch $arch copy --dest-oci-accept-uncompressed-layers docker://$Image containers-storage:$Image
    skopeo --override-arch $arch copy --dest-oci-accept-uncompressed-layers containers-storage:$Image oci:$ociArchDir:$image
  done
  tar cvCf $ociDir -  $arch | xz -9v > $ociArchDir.tar.xz
done
