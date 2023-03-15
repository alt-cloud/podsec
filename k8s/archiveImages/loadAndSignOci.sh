#!/bin/sh

if [ $# -ne 4 ]
then
  echo -ne "Формат:\n\t$0 имя_архивного_файла архитектура имя_регистратора EMail_подписанта\n"  >&2
  exit 1
fi

archive=$1
arch=$2
# regName=$(basename $3)
regName=$3
signBy="${4}"

if [ ! -f $archive ]
then
  echo "Архив $archive отсутствует"
  echo -ne "Формат:\n\t$0 имя_архивного_файла архитектура имя_регистратора EMail_подписанта\n"  >&2
  exit 1
fi

case $arch in
amd64 | arm64 | arm | ppc64le | 386) :;;
*)
  echo "Неизвестная архитектура $arch" >&2
  echo "Допустимые: amd64, arm64, arm, ppc64le, 386" >&2
  echo -ne "Формат:\n\t$0 архитектура имя_регистратора [EMail_подписи]\n" >&2
  exit 3
  ;;
esac

if [ -z "$regName" ]
then
  echo "Не указано имя регистратора" >&2
  echo -ne "Формат:\n\t$0 архитектура имя_регистратора  [EMail_подписи]\n" >&2
  exit 4
fi

ifs=$IFS IFS=.
set -- $regName
IFS=$ifs
if [ $# -eq 1 ]
then
  echo "Имя регистратора должно содержать точку (.) в имени" >&2
  exit 5
fi

TMPDIR=/var/tmp/ociDir.$$
mkdir -p $TMPDIR

if xz -d < $archive | tar xvCf $TMPDIR -
then
  :;
else
  echo "Неуспешное разворачивание архива" >&2
  exit 6
fi

archDir="$TMPDIR/$arch"
if [ ! -d $archDir ]
then
  echo "Неверный формат архива. Каталог архитектуры $arch отсутствует" >&2
  exit 7
fi

archIndexFile="$archDir/index.json"
if [ ! -f "$archIndexFile" ]
then
  echo "Неверный формат архива. Индексный файл архива $arch/index.json отсутствует" >&2
  exit 8
fi

imagesList=$(jq '.manifests[].annotations[]' $archIndexFile)
for image in $imagesList
do
  image=${image:1:-1}
  echo "Разворачиваение образа $image в локальную систему"
  Image="$regName/$image"
  skopeo --override-arch $arch copy oci:$archDir:$image containers-storage:$Image
done

for image in $imagesList
do
  image=${image:1:-1}
  echo "Подпись и передача образа $image в регистратор"
  Image="$regName/$image"
  podman push --tls-verify=false --sign-by="$signBy" $Image
done

rm -rf $TMPDIR

