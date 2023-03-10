#!/bin/sh
# Скрипт производит разворачивание образов из архива, созданным скриптом saveOci.sh
# Скрипт разоврачивает все образы записанный в архиве
# Первым параметром имя архитектуры (amd64 | arm64 | arm | ppc64le | 386)
# Вторым имя регистратора. Оно должно содержать точку (.) в имени.
# На вход команды поступает tar oci-каталога
# Для оптимизации размера архива на (ISO) диске его предварительно следует сжать компрессором xz
# При этом вызов скрипта будет выглядеть например так: xz -d < oci-archive.tar.xz | loadOci.sh amd64 registry.local

if [ $# -ne 2 ]
then
  echo -ne "Формат:\n\t$0 архитектура имя_регистратора\n"
  exit 1
fi

arch=$1
regName=$(basename $2)

case $arch in
amd64 | arm64 | arm | ppc64le | 386) :;;
*)
  echo "Неизвестная архитектура $arch";
  echo "Допустимые: amd64, arm64, arm, ppc64le, 386"
  echo -ne "Формат:\n\t$0 архитектура имя_регистратора\n"
  exit 3
  ;;
esac

if [ -z "$regName" ]
then
  echo "Не указано имя регистратора"
  echo -ne "Формат:\n\t$0 архитектура имя_регистратора\n"
  exit 4
fi

ifs=$IFS IFS=.
set -- $regName
IFS=$ifs
if [ $# -eq 1 ]
then
  echo "Имя регистратора должно содержать точку (.) в имени"
  exit 5
fi

TMPDIR=/var/tmp/ociDir.$$
mkdir $TMPDIR

if tar xvCf $TMPDIR -
then
  :;
else
  echo "Неуспешное разворачивание архива"
  exit 6
fi

archDir="$TMPDIR/$arch"
if [ ! -d $archDir ]
then
  echo "Неверный формат архива. Каталог архитектуры $arch отсутствует"
  exit 7
fi

archIndexFile="$archDir/index.json"
if [ ! -f "$archIndexFile" ]
then
  echo "Неверный формат архива. Индексный файл архива $arch/index.json отсутствует"
  exit 8
fi

imagesList=$(jq '.manifests[].annotations[]' $archIndexFile)
for image in $imagesList
do
  image=${image:1:-1}
  echo "  image=$image"
  Image="$regName/$image"
  skopeo --override-arch $arch copy oci:$archDir:$image containers-storage:$Image
done
rm -rf $TMPDIR
