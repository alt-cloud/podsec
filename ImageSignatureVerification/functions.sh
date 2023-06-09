#!/bin/sh

# Вспомогательные функции
#
# imagesTree
# Преобразует список образов вида
#  [
#    "kaf1.local/flannel-cni-plugin@sha256:e639aba6406e58405dda808b633db113324d0f1ed9f9b03612269a7d08b7b833",
#    "news.local/flannel-cni-plugin@sha256:e639aba6406e58405dda808b633db113324d0f1ed9f9b03612269a7d08b7b833",
#    "news.local/etcd@sha256:381bb6ffd9194578d1801bf06ca10de9cf34ab833ff0bb76f5786f64b73de97a"
#  ]
# в дерево
#  {
#    "sha256:381bb6ffd9194578d1801bf06ca10de9cf34ab833ff0bb76f5786f64b73de97a": [
#      "news.local/etcd"
#    ],
#    "sha256:e639aba6406e58405dda808b633db113324d0f1ed9f9b03612269a7d08b7b833": [
#      "kaf1.local/flannel-cni-plugin",
#      "news.local/flannel-cni-plugin"
#    ]
#  }
imagesTree() {
  jq '[
    .[] |
    {(split("@")[1]):(split("@")[0])} |
    to_entries
    ] |
  flatten |
  group_by(.key) |
  map({key:(.[0].key), value:[.[] | .value]}) |
  from_entries'
}


#######################
# policy functions

# Получить default policy из poliсy.json файла
getDefaultPolicy() {
  configPolicyFile=$1
#   configPolicyFile="$configPolicyFile"
  if [ ! -f $configPolicyFile ]
  then
    return
  fi
  defaultPolicy=$(jq '.default[].type' $configPolicyFile)
  defaultPolicy=${defaultPolicy:1:-1}
  if [ -z "$defaultPolicy" ]
  then
    defaultPolicy="insecureAcceptAnything"
  fi
  echo $defaultPolicy
}

# Получить список регистраторов
# Format:
#  getRegistries configPolicyFile [json]
# Если второй параметр json - вывод в формате json
getRegistries() {
  configPolicyFile=$1
  type=$2
  req='if .transports.docker then .transports.docker | keys else [] end'
  if [ "$type" != 'json' ]
  then
    req+=" | .[]"
  fi
  jq "$req" $configPolicyFile
}

# Получить список регистраторов требующих подписи (type == signedBy)
# Format:
#  getSignedRegistries configPolicyFile [json]
# Если второй параметр json - вывод в формате json
getSignedRegistries() {
  configPolicyFile=$1
  type=$2
  req='if .transports.docker then [.transports.docker | to_entries[] | select(.value[].type == "signedBy") | .key] else [] end'
  if [ "$type" != 'json' ]
  then
    req+=" | .[]"
  fi
  jq "$req" $configPolicyFile
}

# Получить список регистраторов не требующих подписи (type == signedBy)
# Format:
#  getNotSignedRegistries configPolicyFile [json]
# Если второй параметр json - вывод в формате json
getNotSignedRegistries() {
  configPolicyFile=$1
  type=$2
  req='if .transports.docker  then [.transports.docker | to_entries[] | select(.value[].type != "signedBy") | .key] else [] end'
  if [ "$type" != 'json' ]
  then
    req+=" | .[]"
  fi
  jq "$req" $configPolicyFile
}

# Поолучить список траспортов, отличных от docker
# Format:
#  getForbiddenTransports configPolicyFile [json]
# Если второй параметр json - вывод в формате json
getForbiddenTransports() {
  configPolicyFile=$1
  type=$2
  req='if .transports then [.transports | to_entries[] | select(.key != "docker").key] else [] end'
  if [ "$type" != 'json' ]
  then
    req+=" | .[]"
  fi
  jq  "$req" $configPolicyFile
}

# Проверка конфигурацию policy.json
checkPolicyConfig() {
  configPolicyFile=$1
  type=$2
  tab="\t"

  configDir=$(dirname $configPolicyFile)
  ret="\"configDir\":\"$configDir\""

  defaultPolicy=$(getDefaultPolicy $configPolicyFile)
  ret+="\n,$tab\"defaultPolicy\":\"$defaultPolicy\""
  if [ -n "$DEBUG" ]
  then
    echo "defaultPolicy=$defaultPolicy"
  fi

  if [ $defaultPolicy != 'reject' ]
  then
    ret+="\n,$tab\"incorrectDefaultPolicy\":\"$defaultPolicy\"\n"
    if [ -n "$DEBUG" ]
    then
      echo -ne "В configPolicyFile установлена политика по умолчанию '$defaultPolicy' отличная от reject\n\n" >&2
    fi
  fi

  defaultSigStore=$(getDefaultSigStore $configDir)
  if [ -z "$defaultSigStore" ]
  then
    ret+="\n$tab,\"noDefaultSigStore\":\"true\"\n"
    if [ -n "$DEBUG" ]
    then
      echo -ne "В YAML-файлах $configDir/registries.d/ отсутствует URL хранителя подписи по умолчанию default-docker.lookaside\n\n" >&2
    fi
  fi

  signedRegistries=$(getSignedRegistries $configPolicyFile json)
  if [ -n "$DEBUG" ]
  then
    echo "signedRegistries=$signedRegistries" >&2
  fi
  ret+="\n,$tab\"signedRegistries\":$signedRegistries"

  notSignedRegistries=$(getNotSignedRegistries $configPolicyFile json)
  if [ -n "$DEBUG" ]
  then
    echo "notSignedRegistries=$notSignedRegistries" >&2
  fi
  ret+="\n,$tab\"notSignedRegistries\":$notSignedRegistries"

  forbiddenTransports=$(getForbiddenTransports $configPolicyFile json)
  if [ -n "$DEBUG" ]
  then
    echo "forbiddenTransports=$forbiddenTransports" >&2
  fi
  ret+="\n,$tab\"forbiddenTransports\":$forbiddenTransports"
  echo -ne "$ret"
}

#######################
# SIGSTORE functions
#  Объединить все yaml-файлы в директории ${1}/registries.d и олучить единый JSON
joinSigStories() {
  ret=
  configDir="${1}/registries.d"
  yamlFiles=$(echo $configDir/*.yaml)
  if [ "$yamlFiles" == "$configDir/*.yaml" ]
  then
    echo "{}"
    return
  fi
  for yamlFile in $yamlFiles
  do
    yaml=$(yq . $yamlFile)
    ret="${ret}${ret:+,}$yaml"
  done
  ret="[$ret]"
  echo $ret | jq 'reduce .[] as $item ({}; . *= $item)'
}

getDefaultSigStore()  {
  configDir=$1
  joinSigStories=$(joinSigStories $configDir)
  lookaside=$(echo $joinSigStories | yq '."default-docker".lookaside')
  if [ "$lookaside" != 'null' ]
  then
    echo $lookaside
  fi
}


#  Вернуть Sigstore для образа или его части включая registry, которые наиболее полно соответсвует описание в файлах $1/registries.d/*.yaml
#  Возвращается JSON-список из одного (lookaside) или двух элементов
#  {
#    "lookaside": "http://...",
#    "sigstore": "http://..."
#  }
getSigStoreList() {
  configDir=$1
  image=$2
  # Объединить описания в файлах $configDir/registries.d/*.yaml
  joinSigStories=$(joinSigStories $configDir)
  # Отсортировать .docker.key по уменьшению длины ключа, выбрать первый соотвествующий $image
  echo $joinSigStories | yq "if .docker then [.docker | to_entries | sort_by(.key|(-length))[] | select(.key == \"$image\"[0:.key|length])][0].value else empty end"
}


#  Вернуть URL файлов каталога подписей в файлах $1/registries.d/*.yaml URL-адрес каталога подписей в SigStore
#  Каталог содержит файлы подписей - signature-1, signature-, ...
getSigStoreURLForImage() {
  configDir=$1
  image=$2
  joinSigStories=$(joinSigStories $configDir)
  registry=$(echo \"$image\" | jq '. | split("/")[0]')
  url=$(echo \"$image\" | jq '. | split("/")[1:] | join("/")' | tr ':' '=')
  if [ -n "$registry" ]
  then
    lookaside=$(getSigStoreList $configDir $image | jq '.lookaside | rtrimstr("/")')
  else
    lookaside=$(getDefaultSigStore $configDir)
  fi
  url=$(echo "$lookaside/$url" | tr -d '"')
  echo $url
}
