#!/bin/sh

defaultPolicy=$(jq '.default[].type' /etc/containers/policy.json  | tr -d '"')
if [ $defaultPolicy != 'reject' ]
then
  echo "В /etc/containers/policy.json установлена политика по умолчанию '$defaultPolicy' отличная от reject"
  exit 1
fi

notSigned=$(jq '.transports.docker  | to_entries | .[]  | if .value[].type != "signedBy" then .key else empty end' /etc/containers/policy.json)
if [ -n "$notSigned" ]
then
  echo "Регистраторы не использующие механизм подписи в  /etc/containers/policy.json:"
  echo $notSigned | tr ' ' "\n"
  echo
#   exit 1
fi

registries=$(jq '.transports.docker | keys | .[]' /etc/containers/policy.json | tr -d '"')
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

in="podman images --format json |
jq '[.[].Names | .[]] |
map(
  select(
$in  )
) | .[]'
"

out="podman images --format json |
 jq '[.[].Names | .[]] |
map(
  select(
$out  )
) | .[]'
"

TMPFILE="/tmp/checkImagesSignature.$$"
echo -ne "$in" > $TMPFILE
in=$(sh $TMPFILE | tr -d '"')

echo -ne "$out" > $TMPFILE
out=$(sh $TMPFILE | grep -v "localhost/podman-pause" | tr -d '"')
rm -f $TMPFILE

if [ -n "$out" ]
then
  echo "Образы вне политики файла /etc/containers/policy.json:"
  echo $out | tr ' ' "\n"
  echo
fi

if [ -n "$out" ]
then
  echo "Образы согласно политики файла /etc/containers/policy.json:"
  echo $in | tr ' ' "\n"
  echo
fi

for image in $in
do
  podman pull --tls-verify=false $image
done
