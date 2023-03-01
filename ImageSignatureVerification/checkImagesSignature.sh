#!/bin/sh

export mes="\"host\":\"$HOSTNAME\""
defaultPolicy=$(jq '.default[].type' /etc/containers/policy.json  | tr -d '"')
if [ $defaultPolicy != 'reject' ]
then
  mes="${mes}\n\"incorrectDefaultPolicy\":\"$defaultPolicy\""
#   echo "В /etc/containers/policy.json установлена политика по умолчанию '$defaultPolicy' отличная от reject"
  echo -ne "{$mes}" | tr "\n" ',' | jq .
  #exit 1
fi

notSigned=$(jq '.transports.docker  | to_entries | .[]  | if .value[].type != "signedBy" then .key else empty end' /etc/containers/policy.json)
if [ -n "$notSigned" ]
then
#   echo "Регистраторы не использующие механизм подписи в  /etc/containers/policy.json:"
  notSignedRegistry=$(echo $notSigned | tr ' ' "\n")
#   echo -ne "$notSignedRegistry\n"
  mes="${mes}\n\"notSignedRegistry\":[$notSignedRegistry]"
#   exit 1
fi


export registries=$(jq '.transports.docker | keys | .[]' /etc/containers/policy.json | tr -d '"')

checkUserImages() {
  user=$1
  mes="${mes}\n\"$user\": {\"user\": \"$user\""
  n=0
  for registry in $registries
  do
  #   echo $registry
    if [ $n -eq 0 ]
    then
      in="    (. | startswith(\"$registry/\"))\n"
      out="    (. | startswith(\"$registry/\") | not)\n"
    else
      in="$in    or \n    (. | startswith(\"$registry/\"))\n"
      out="$out    and \n    (. | startswith(\"$registry/\") | not)\n"
    fi
    let n=$n+1
  done

  in="su - -c 'podman images --format json' $user 2>/dev/null |
  jq '[.[] | if  has(\"Names\") then .Names else [.Id] end | .[]] |
map(
  select(
$in  )
) | .[]'
"

  out="su - -c 'podman images --format json' $user 2>/dev/null |
  jq '[.[] | if  has(\"Names\") then .Names else [.Id] end | .[]] |
map(
  select(
$out  )
) | .[]'
"

  TMPFILE="/tmp/checkImagesSignature.$$"
  echo -ne "$in" > $TMPFILE
  in=$(sh $TMPFILE )

  echo -ne "$out" > $TMPFILE
  out=$(sh $TMPFILE | grep -v "localhost/podman-pause" )
  rm -f $TMPFILE

  TMPFILE="${TMPFILE}--"
  if [ -n "$out" ]
  then
#     echo "Рабочее местр $HOSTNAME. пользователь $user: Образы вне политики файла /etc/containers/policy.json:"
    outPolicyImages=$(echo $out | tr ' ' "\n")
#     echo "$outPolicyImages\n"
    mes="${mes}\n\"outPolicyImages\": [$outPolicyImages]"
  fi

  if [ -n "$in" ]
  then
#     echo "Рабочее местр $HOSTNAME. пользователь $user: Образы согласно политики файла /etc/containers/policy.json:"
    inPolicyImages=$(echo $in | tr ' ' "\n")
#     echo "$inPolicyImages\n"
    mes="${mes}\n\"inPolicyImages\": [$inPolicyImages]"
  fi
  inCorrectImages=
  for image in $in
  do
    Image=$(echo $image | tr -d '"')
#     echo -ne "Проверка образа $Image... "
    if podman pull --tls-verify=false $Image >/dev/null 2>$TMPFILE
    then :; # echo "OK";
    else
#       echo "Рабочее местр $HOSTNAME. пользователь $user имеет некорректный образ:"
#       cat $TMPFILE
      inCorrectImages="{$image:\"$(tr '"' '\"' < $TMPFILE)\"}"
    fi
  done
  mes="${mes},\"inCorrectImages\":[$inCorrectImages]"
  mes="${mes}}"
  rm -f $TMPFILE
}

#checkUserImages root
# user=kaf
# checkImages $user
# exit

for user in /home/*
do
  if [ -d "$user/.local/share/containers/storage/overlay" ]
  then
    user=$(basename $user)
#     echo -ne "\n\n------------------------$user\n"
    checkUserImages $user
  fi
done
mes=$(echo -ne "{$mes}" | tr "\n" ',')
# echo -ne "MES=$mes\n"
echo -ne "$mes"
# | jq .

