#!/bin/sh
# Скрипт производит разворачивание образов из архива, созданным скриптом saveOci.sh
# Скрипт разоврачивает все образы записанный в архиве
# Первым параметром указывается имя архива
# Вторым параметром имя архитектуры (amd64 | arm64 | arm | ppc64le | 386)
# Третьим имя регистратора. Оно должно содержать точку (.) в имени.

ociFile=$1
arch=$2
regName=$3

if [ $# -ne 3 ]
then
  echo -ne "Формат:\n\t$0 файл_архива архитектура имя_регистратора\n"
  exit 1
fi

if [ ! -f $ociFile ]
then
  echo "Файл архива $ociFile отсутсвует"
  echo -ne "Формат:\n\t$0 файл_архива архитектура имя_регистратора\n"
  exit 2
fi

case $arch in
amd64 | arm64 | arm | ppc64le | 386) :;;
*)
  echo "Неизвестная архитектура $arch";
  echo "Допустимые: amd64, arm64, arm, ppc64le, 386"
  echo -ne "Формат:\n\t$0 файл_архива архитектура имя_регистратора\n"
  exit 3
  ;;
esac

if [ -z "$regName" ]
then
  echo "Не указано имя регистратора"
  echo -ne "Формат:\n\t$0 файл_архива архитектура имя_регистратора\n"
  exit 4
fi

ifs=$IFS
IFS=.
set -- $regName
IFS=$ifs
if [ $# -eq 1 ]
then
  echo "Имя регистратора должно содержать точку (.) в имени"
  exit 5
fi

TMPDIR=/tmp/ociDir.$$
mkdir $TMPDIR

if xz -d < $ociFile | tar xvCf $TMPDIR -
then
  :;
else
  echo "Неуспешное разворачивание архива"
  exit 6
fi
archDir="$TMPDIR/$arch"

if [ ! -d $archDir ]
then
  echo "Неверный формат архива. Каталог архитектуры $arch отсутсвует"
  exit 7
fi

baseImagesList=$(jq .manifests[].annotations[] $archDir/index.json)
for image in $baseImagesList
do
  image=${image:1:-1}
  echo "  image=$image"
  Image="$regName/$image"
  skopeo --override-arch $arch copy oci:$archDir:$image containers-storage:$Image
done
rm -rf $TMPDIR
