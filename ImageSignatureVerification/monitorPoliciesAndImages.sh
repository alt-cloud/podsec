#!/bin/sh

script=$(basename $0)

TMPFILE=/tmp/$script.$$
./checkImagesSignature.sh > $TMPFILE

# TMPFILE="/tmp/images.json"
host=$(jq .host $TMPFILE)
messabe="HOST %host\n"

users=$(jq '.users | keys[]' $TMPFILE)

user="root"
message+="\n\n---------------------------------------------------------\n"
message+="СИСТЕМНЫЕ НАСТРОЙКИ ROOTFULL РЕЖИМ, ПОЛЗОВАТАТЕЛЬ root:\n"
set -- $( jq ".users.$user.configDir, .users.$user.defaultPolicy, .users.$user.noDefaultSigStore" $TMPFILE)
configDir=${1:1:-1} defaultPolicy=${2:1:-1} noDefaultSigStore=$3
message+="Каталог конфигурации политик: $configDir\n";
message+="Политика по умолчанию: $defaultPolicy\n"
if [ "$defaultPolicy" != "reject" ]
then
  message+="\nПОЛИТИКА ПО УМОЛЧАНИЮ ОТЛИЧАЕТСЯ ОТ РЕКОМЕНДУЕМОЙ \"reject\"!!!\n"
fi
if [ "$noDefaultSigStore" ]
then
  message+="\nВ ФАЙЛЕ $configDir/registrers.d/default.yaml НЕ УКАЗАН URL ХРАНИЛИЩА ПОДПИСЕЙ (default-docker.lookaside)\n"
fi
forbiddenTransports=$(jq ".users.$user.forbiddenTransports[]" $TMPFILE)
if [ -n "$forbiddenTransports" ]
then
  message+="\nВ ФАЙЛЕ $configDir/policy.json ОПИСАНЫ ТРАНСПОРТЫ ОТЛИЧНЫЕ ОТ \"docker\": $forbiddenTransports\n"
fi

outPolicyImagesTree=$(jq ".users.$user.outPolicyImagesTree" $TMPFILE | sed ':a;N;$!ba;s!\n!\\n!g')
if [ -n "$outPolicyImagesTree" ]
then
  message+="\nОБРАЗЫ ВНЕ СПИСКА РЕГИСТРАТОРОВ ОПИСАННЫХ В $configDir/policy.json:\n$outPolicyImagesTree\n"
fi

inCorrectImages=$(jq ".users.$user.inCorrectImages" $TMPFILE | sed ':a;N;$!ba;s!\n!\\n!g')
if [ -n "$inCorrectImages" ]
then
  message+="\nНЕКОРРЕКТНЫЕ ИЛИ ОТСУТСВУЮЩИЕ  НА РЕГИСТРАТОРАХ ОБРАЗЫ:\n$inCorrectImages\n"
fi

notSignedImagesTree=$(jq ".users.$user.notSignedImagesTree" $TMPFILE | sed ':a;N;$!ba;s!\n!\\n!g')
if [ -n "$notSignedImagesTree" ]
then
  message+="\nНЕПОДПИСАННЫЕ ОБРАЗЫ:\n$notSignedImagesTree\n"
fi


for user in $users
do
  if [ $user == '"root"' ]
  then
    continue
  fi
  user=${user:1:-1}
#   echo $user
  message+="\n\n----------------------------------------------------------\n"
  message+="ПОЛЬЗОВАТЕЛЬ $user:\n"
  set -- $( jq ".users.$user.configDir, .users.$user.defaultPolicy, .users.$user.noDefaultSigStore" $TMPFILE)
  configDir=${1:1:-1} defaultPolicy=${2:1:-1} noDefaultSigStore=$3
  message+="Каталог конфигурации политик: $configDir\n";
  message+="Политика по умолчанию: $defaultPolicy\n"
  if [ "$defaultPolicy" != "reject" ]
  then
    message+="\nПОЛИТИКА ПО УМОЛЧАНИЮ ОТЛИЧАЕТСЯ ОТ РЕКОМЕНДУЕМОЙ \"reject\"!!!\n"
  fi
  if [ "$noDefaultSigStore" ]
  then
    message+="\nВ ФАЙЛЕ $configDir/registrers.d/default.yaml НЕ УКАЗАН URL ХРАНИЛИЩА ПОДПИСЕЙ (default-docker.lookaside)\n"
  fi
  forbiddenTransports=$(jq ".users.$user.forbiddenTransports[]" $TMPFILE)
  if [ -n "$forbiddenTransports" ]
  then
    message+="\nВ ФАЙЛЕ $configDir/policy.json ОПИСАНЫ ТРАНСПОРТЫ ОТЛИЧНЫЕ ОТ \"docker\": $forbiddenTransports\n"
  fi

  outPolicyImagesTree=$(jq ".users.$user.outPolicyImagesTree" $TMPFILE | sed ':a;N;$!ba;s!\n!\\n!g')
  if [ -n "$outPolicyImagesTree" ]
  then
    message+="\nОБРАЗЫ ВНЕ СПИСКА РЕГИСТРАТОРОВ ОПИСАННЫХ В $configDir/policy.json:\n$outPolicyImagesTree\n"
  fi

  inCorrectImages=$(jq ".users.$user.inCorrectImages" $TMPFILE | sed ':a;N;$!ba;s!\n!\\n!g')
  if [ -n "$inCorrectImages" ]
  then
    message+="\nНЕКОРРЕКТНЫЕ ИЛИ ОТСУТСВУЮЩИЕ  НА РЕГИСТРАТОРАХ ОБРАЗЫ:\n$inCorrectImages\n"
  fi

  notSignedImagesTree=$(jq ".users.$user.notSignedImagesTree" $TMPFILE | sed ':a;N;$!ba;s!\n!\\n!g')
  if [ -n "$notSignedImagesTree" ]
  then
    message+="\nНЕПОДПИСАННЫЕ ОБРАЗЫ:\n$notSignedImagesTree\n"
  fi

done

rm -f $TMPFILE

echo -ne $message
