#!/bin/sh

. ./functions.sh

checkUserImages() {
  user=$1
  configDir=$2
  tab="\\t\\t"
  policyFile="$configDir/policy.json"
  ret="\n$tab\"user\": \"$user\"\n"
  userPolicyConfig=$(checkPolicyConfig $policyFile)
  ret+=",$userPolicyConfig"
  registries=$(getRegistries $policyFile)
  if [ -z "$registries" ]
  then
    registries='""'
  fi
  n=0
  for Registry in $registries
  do
    registry=${Registry:1:-1}
    if [ $n -eq 0 ]
    then
      in="    (. | startswith(\"$registry/\"))\n"
      out="    (. | startswith(\"$registry/\") | not)\n"
    else
      in="$in    or \n    (. | startswith(\"$registry/\"))\n"
      out="$out    and \n    (. | startswith(\"$registry/\") | not)\n"
    fi
    let n=$n+1$notSigned
  done

  in="su - -c 'podman images --format json' $user 2>/dev/null |
  jq '[[.[] | if  has(\"RepoDigests\") then .RepoDigests else [.Id] end | .[]] |
map(
  select(
$in  )
) | sort| unique | .[]]' | jq .
"

  out="su - -c 'podman images --format json' $user 2>/dev/null |
  jq '[[.[] | if  has(\"RepoDigests\") then .RepoDigests else [.Id] end | .[]] |
map(
  select(
$out  )
) | sort| unique | .[]]' | jq .
"

  TMPFILE="/tmp/checkImagesSignature.$$"
  echo -ne "$in" > $TMPFILE
  in=$(sh $TMPFILE )
#   cp $TMPFILE "/tmp/in.$user"

  echo -ne "$out" > $TMPFILE
  out=$(sh $TMPFILE)
#   cp $TMPFILE "/tmp/outtm.$user"
  rm -f $TMPFILE

  if [ -n "$out" ]
  then
    outPolicyImages=$(echo -ne "$out")
    if [ -n "$DEBUG" ]
    then
      echo "Рабочее место $HOSTNAME, пользователь $user: Образы вне политики файла $policyFile:" >&2
      echo -ne "$outPolicyImages\n\n" >&2
    fi
#     outPolicyImages=$(echo $outPolicyImages | jq .)
    ret+="\n,\"outPolicyImages\": $outPolicyImages"
  fi

  if [ -n "$in" ]
  then
    inPolicyImages=$(echo -ne "$in")
    if [ -n "$DEBUG" ]
    then
      echo "Рабочее местр $HOSTNAME, пользователь $user: Образы согласно политики файла $policyFile:" >&2
      echo -ne "$inPolicyImages\n\n" >&2
    fi
#     inPolicyImages=$(echo $inPolicyImages | jq .)
    ret+="\n,\"inPolicyImages\": $inPolicyImages"
  fi

  inCorrectImages=
  images=$in
  if [ -n "$CHECKALLIMAGES" ]
  then
    images="$in $out"
  fi
  for image in $(echo $images | jq '.[]')
  do
    Image=${image:1:-1}
    if podman pull --tls-verify=false $Image >/dev/null 2>$TMPFILE
    then :; # echo "OK";
    else
      if [ -n "$DEBUG" ]
      then
        echo "Рабочее место $HOSTNAME, пользователь $user имеет некорректный образ:" >&2
        cat $TMPFILE >&2
        echo -ne "\n\n" >&2
      fi
      inCorrectImages+=$(echo ${inCorrectImages:+,})
      inCorrectImages+=$(tr "\n" ' '<$TMPFILE | jq --raw-input ". | {$image:.}"  )
    fi
  done
  ret+=",\"inCorrectImages\":[$inCorrectImages]"

  notSignedImages=
  signedImages=
  for image in $(echo $images | jq '.[]')
  do
    sigStoreURL=$(getSigStoreURLForImage $configDir ${image:1:-1})
    sigStoreURL="$sigStoreURL/signature-1"
    if wget -q -O $TMPFILE $sigStoreURL 2>/dev/null
    then
      signedImages+=$(echo ${signedImages:+,}$image)
    else
      notSignedImages+=$(echo ${notSignedImages:+,}$image)
    fi
  done
  rm -f $TMPFILE
  ret+="\n,\"signedImages\": [$signedImages]"
  ret+="\n,\"notSignedImages\": [$notSignedImages]"

  echo -ne "$ret";
}

checkUserConfigAndImages() {
  # удалить конечные /
  userDir=$(dirname "$1/./")
  user=$(basename $userDir)
  if [ "$user" == 'root' ]
  then
    configDir="/etc/containers"
    policyFile="/etc/containers/policy.json"
  else
    if [ ! -d "$userDir/.local/share/containers/storage/overlay" ]
    then
      return
    fi
    configDir="$userDir/.config/containers"
    policyFile="$userDir/.config/containers/policy.json"
    if [ ! -f $policyFile ]
    then
      configDir="/etc/containers"
      policyFile="/etc/containers/policy.json"
    fi
  fi
  userImages=$(checkUserImages $user $configDir)
  ret="\"$user\":{$userImages}"
  echo -ne "$ret"
}


checkUsersConfigAndImages() {
  ret=
#   userDir="/home/imagedeveloper/"
#   userImages=$(checkUserConfigAndImages $userDir)
#   ret+="\n$userImages"
  userDir="/root"
  userImages=$(checkUserConfigAndImages $userDir)
  ret+="\n$userImages"
  for userDir in /home/*
  do
    if [ -d "$userDir/.local/share/containers/storage/overlay" ]
    then
      userImages=$(checkUserConfigAndImages $userDir)
      user=$(basename $userDir)
      ret+="\n,\"$user\":{$userImages}"
    fi
  done
  ret="\"users\":{$ret}"
  echo -ne "$ret"
}


# MAIN
mes="$tab\"host\":\"$HOSTNAME\",\n"

mes+=$(checkUsersConfigAndImages)
echo -ne "{${mes}}"

