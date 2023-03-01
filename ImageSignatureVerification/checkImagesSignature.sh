#!/bin/sh

getSigStore() {
  image=$1
  registry=$(echo $image | jq '. | split("/")[0]')
  url=$(echo $image | jq '. | split("/")[1:] | join("/")' | tr ':' '=')
  if [ -n "$registry" ]
  then
    lookaside=$(yq "if .docker[$registry] then .docker[$registry].lookaside else .\"default-docker\".lookaside end" < /etc/containers/registries.d/default.yaml)
  else
    lookaside=$(yq ".\"default-docker\".lookaside end" < /etc/containers/registries.d/default.yaml)
  fi
  url=$(echo "$lookaside/$url" | tr -d '"')
  echo $url
}

export mes="\"host\":\"$HOSTNAME\""
defaultPolicy=$(jq '.default[].type' /etc/containers/policy.json  | tr -d '"')
if [ $defaultPolicy != 'reject' ]
then
  mes="${mes}\n\"incorrectDefaultPolicy\":\"$defaultPolicy\""
  if [ -n "$DEBUG" ]
  then
    echo -ne "В /etc/containers/policy.json установлена политика по умолчанию '$defaultPolicy' отличная от reject\n\n" >&2
  fi
fi

notSigned=$(jq '.transports.docker  | to_entries | .[]  | if .value[].type != "signedBy" then .key else empty end' /etc/containers/policy.json)
if [ -n "$notSigned" ]
then
  notSignedRegistry=$(echo $notSigned | tr ' ' "\n")
  if [ -n "$DEBUG" ]
  then
    echo "Регистраторы не использующие механизм подписи в  /etc/containers/policy.json:" >&2
    echo -ne "$notSignedRegistry\n\n" >&2
  fi
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
  jq '[.[] | if  has(\"RepoDigests\") then .RepoDigests else [.Id] end | .[]] |
map(
  select(
$in  )
) | sort| unique | .[]'
"

  out="su - -c 'podman images --format json' $user 2>/dev/null |
  jq '[.[] | if  has(\"RepoDigests\") then .RepoDigests else [.Id] end | .[]] |
map(
  select(
$out  )
) | sort| unique | .[]'
"

  TMPFILE="/tmp/checkImagesSignature.$$"
  echo -ne "$in" > $TMPFILE
  in=$(sh $TMPFILE )

  echo -ne "$out" > $TMPFILE
  out=$(sh $TMPFILE | grep -v "localhost/podman-pause" )
  rm -f $TMPFILE

  if [ -n "$out" ]
  then
    outPolicyImages=$(echo $out | tr ' ' "\n")
    if [ -n "$DEBUG" ]
    then
      echo "Рабочее местр $HOSTNAME, пользователь $user: Образы вне политики файла /etc/containers/policy.json:" >&2
      echo -ne "$outPolicyImages\n\n" >&2
    fi
    mes="${mes}\n\"outPolicyImages\": [$outPolicyImages]"
  fi

  if [ -n "$in" ]
  then
    inPolicyImages=$(echo $in | tr ' ' "\n")
    if [ -n "$DEBUG" ]
    then
      echo "Рабочее местр $HOSTNAME, пользователь $user: Образы согласно политики файла /etc/containers/policy.json:" >&2
      echo -ne "$inPolicyImages\n\n" >&2
    fi
    mes="${mes}\n\"inPolicyImages\": [$inPolicyImages]"
  fi
  inCorrectImages=
  images=$in
  if [ -n "$CHECKALLIMAGES" ]
  then
    images="$in $out"
  fi
  for image in $images
  do
    Image=$(echo $image | tr -d '"')
    if podman pull --tls-verify=false $Image >/dev/null 2>$TMPFILE
    then :; # echo "OK";
    else
      if [ -n "$DEBUG" ]
      then
        echo "Рабочее местр $HOSTNAME, пользователь $user имеет некорректный образ:" >&2
        cat $TMPFILE >&2
        echo -ne "\n\n" >&2
      fi
      inCorrectImages="{$image:\"$(tr '"' '\"' < $TMPFILE)\"}"
    fi
  done
  mes="${mes},\"inCorrectImages\":[$inCorrectImages]"

  notSignedImages=
  signedImages=
  for image in $images
  do
    sigStoreURL=$(getSigStore $image)
    sigStoreURL="$sigStoreURL/signature-1"
    if wget -q -O $TMPFILE $sigStoreURL 2>/dev/null
    then
      signedImages=$(echo ${signedImages}${signedImages:+\\n}$image)
    else
      notSignedImages=$(echo ${notSignedImages}${notSignedImages:+\\n}$image)
    fi
  done
  mes="${mes}\n\"signedImages\": [$signedImages]"
  mes="${mes}\n\"notSignedImages\": [$notSignedImages]"

  mes="${mes}}"
  rm -f $TMPFILE
}

checkUserImages root

for user in /home/*
do
  if [ -d "$user/.local/share/containers/storage/overlay" ]
  then
    user=$(basename $user)
    checkUserImages $user
  fi
done
mes=$(echo -ne "{$mes}" | tr "\n" ',')
echo -ne "$mes"

