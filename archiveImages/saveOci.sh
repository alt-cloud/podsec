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

set -x
if [ $# -lt 1 ]
then
  echo "Не указан каталог архивирования образов"
  echo -ne "Формат:\n\t$0  <каталог_архивирования_образов> <архитектура>,<архитектура>,...|all <образ> ..."
  exit 1
fi

if [ $# -eq 1 ]
then
  echo "Не указан список образов"
  echo -ne "Формат:\n\t$0  <каталог_архивирования_образов> <архитектура>,<архитектура>,...|all <образ> ..."
  exit 1
fi

ociDir=$1
archs=$2
shift
shift
images=$*

if [ -d $ociDir ]
then
  echo "OCI-каталог уже существует"
  exit 1
fi

regName='registry.altlinux.org/k8s-p10'

case $archs in
  'all') archs='amd64 arm64 arm ppc64le 386';;
  *)
    ifs=$IFS IFS=,
    set -- $archs
    archs=$*
    IFS=$ifs
    for arch in $archs
    do
      case $1 in
        amd64 | arm64 | arm | ppc64le | 386) :;;
        *)
          echo "Неизвестная архитектура $arch";
          echo "Допустимые: amd64, arm64, arm, ppc64le, 386"
          echo -ne "Формат:\n\t$0 каталог_разворачивания_врхивов [архитектура ...]\n"
          exit 2
      esac
    done

esac
mkdir $ociDir


for arch in $archs
do
  echo $arch
  ociArchDir="$ociDir/$arch"
  if [ -d $ociArchDir ]
  then
    mkdir $ociArchDir
  fi
  for image
  do
    echo "  image=$image"
    Image="$regName/$image"
    skopeo --override-arch $arch copy --dest-oci-accept-uncompressed-layers docker://$Image containers-storage:$Image
    skopeo --override-arch $arch copy --dest-oci-accept-uncompressed-layers containers-storage:$Image oci:$ociArchDir:$image
  done
  tar cvCf $ociDir -  $arch | xz -9v > $ociArchDir.tar.xz
  rm -rf $ociArchDir
done
