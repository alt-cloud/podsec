#!/bin/sh

getSigStore() {
  image=$1
  registry=$(echo $image | jq '. | split("/")[0]')
  url=$(echo $image | jq '. | split("/")[1:] | join("/")' | tr ':' '=')
  if [ -n "$registry" ]
  then
    lookaside=$(yq "if .docker[$registry] then .docker[$registry].lookaside else .\"default-docker\".lookaside end" < /etc/containers/registries.d/default.yaml)
  else
    lookaside=$(yq ".\"default-docker\".lookaside" < /etc/containers/registries.d/default.yaml)
  fi
  url=$(echo "$lookaside/$url" | tr -d '"')
  echo $url
}

getDefaultPolicy() {
  configPolicyFile=$1
  configPolicyFile="$configPolicyFile"
  if [ ! -f $configPolicyFile ]
  then
    return
  fi
  defaultPolicy=$(jq '.default[].type' $configPolicyFile  | tr -d '"')
  if [ -z "$defaultPolicy" ]
  then
    defaultPolicy="insecureAcceptAnything"
  fi
  echo $defaultPolicy
}

getSignedRegistries() {
  configPolicyFile=$1
  jq '.transports.docker | to_entries[] | select(.value[].type == "signedBy") | .key' < $configPolicyFile
}

getNotSignedRegistries() {
  configPolicyFile=$1
  jq '.transports.docker | to_entries[] | select(.value[].type != "signedBy") | .key' < $configPolicyFile
}

getForbiddenTransports() {
  configPolicyFile=$1
  jq '.transports | to_entries[] | select(.key != "docker").key' < $configPolicyFile
}

checkPolicyConfig() {
  configPolicyFile=$1
  ret=
  defaultPolicy=$(getDefaultPolicy $configPolicyFile)
  ret="\"defaultPolicy\":\"$defaultPolicy\""
#   echo "defaultPolicy=$defaultPolicy"

  signedRegistries=$(getSignedRegistries $configPolicyFile)
  if [ -n "$DEBUG" ]
  then
    echo "signedRegistries=$signedRegistries" >&2
  fi
  signedRegistriesList=
  for signedRegistry in $signedRegistries
  do
    signedRegistriesList=$(echo ${signedRegistriesList}${signedRegistriesList:+\\n}$signedRegistry)
  done
  ret="${ret},\"signedRegistries\":[$signedRegistriesList]"

  notSignedRegistries=$(getNotSignedRegistries $configPolicyFile)
  if [ -n "$DEBUG" ]
  then
    echo "notSignedRegistries=$notSignedRegistries" >&2
  fi
  notSignedRegistriesList=
  for notSignedRegistry in $signedRegistries
  do
    notSignedRegistriesList=$(echo ${notSignedRegistriesList}${notSignedRegistriesList:+\\n}$notSignedRegistry)
  done
  ret="${ret},\"notSignedRegistries\":[$notSignedRegistries]"

  forbiddenTransports=$(getForbiddenTransports $configPolicyFile)
  if [ -n "$DEBUG" ]
  then
    echo "forbiddenTransports=$forbiddenTransports" >&2
  fi
  forbiddenTransportList=
  for forbiddenTransport in $forbiddenTransports
  do
    forbiddenTransportList=$(echo ${forbiddenTransportList}${forbiddenTransportList:+\\n}$forbiddenTransport)
  done
  ret="${ret},\"forbiddenTransport\":[$forbiddenTransport]"

  configDir=$(dirname configPolicyFile)
  echo "{$ret}"
}

rootjson=$(checkPolicyConfig /etc/containers/policy.json | jq .)
mes="\"root\":$rootjson"

for user in /home/*
do
#   echo "USER=$user" >&2
  if [ ! -d  "$user/.config/containers" ]
  then
    continue
  fi
  policyFile="$user/.config/containers/policy.json"
  user=`basename $user`
  if [ -f $policyFile ]
  then
    userjson=$(checkPolicyConfig $policyFile | jq .)
  else
    userjson=$rootjson
  fi
  mes="$mes,\"$user\":$userjson"
done
echo "{$mes}"

