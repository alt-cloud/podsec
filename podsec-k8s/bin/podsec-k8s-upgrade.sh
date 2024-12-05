#!/bin/sh

export TEXTDOMAINDIR='/usr/share/locale'
export TEXTDOMAIN='podsec-k8s'

function getCurrentKubeVersion() {
  kubeVersion=''
  kubeapiVersion=$(kubectl -n kube-system get pod/kube-apiserver-host-70 -o yaml 2>/dev/null| yq -r '.spec.containers[0].image')
  if [ -n "$kubeapiVersion" ]
  then
    kubeapiVersion=$(basename $kubeapiVersion)
    ifs=$IFS; IFS=:; set -- $kubeapiVersion; IFS=$ifs; kubeVersion=${2:1}
  fi
  echo $kubeVersion
}

function getMinorVersion() {
	ifs=$IFS
	IFS=.
	set -- $1
	IFS=$ifs
	echo "$1.$2"
}

function getPrevMinorVersion() {
	ifs=$IFS
	IFS=.
	set -- $1
	IFS=$ifs
	let prev=$2-1
	echo "$1.$prev"
}

function getNextKubeVersions() {
  curMinorKubeVersion=$1
  if [ $U7S_REGISTRY == 'registry.local' ]
  then
    protocol='http'
  else
    protocol='https'
  fi
  kubeVersions=$(curl -sk $protocol://$U7S_REGISTRY/v2/k8s-c10f2/kube-apiserver/tags/list | jq -r .tags[] | sort)
  ret=''
  for kubeVersion in $kubeVersions
  do
    kubeVersion=${kubeVersion:1}
    if [[ "$kubeVersion" > "$curMinorKubeVersion" ]]
    then
      ret+=" $kubeVersion"
    fi
  done
  echo $ret
}

function setRPMRegistries() {
  if [ "$U7S_REGISTRY" = 'registry.local' ]
  then
    export U7S_RPMRegistryClassic='http://sigstore.local:81/rpms'
    export U7S_RPMRegistryNoarch='http://sigstore.local:81/rpms'
  elif [ "${U7S_PLATFORM:0:8}" = 'k8s-c10f' ]
  then
    export U7S_RPMRegistryClassic='http://update.altsp.su/c10f2/branch/x86_64/RPMS.classic'
    export U7S_RPMRegistryNoarch='http://update.altsp.su/c10f2/branch/noarch/RPMS.classic'
  fi
}

function loadRpmPackages() {
  kubeVersions="$*"
  tmpDir='/tmp/RPMS'
  mkdir -p $tmpDir
  rm -f $tmpDir/*
  listClassicRPMS=''
  listNoarchRPMS=''
  setRPMRegistries
  curl --connect-timeout 600 -sk ${U7S_RPMRegistryClassic}/ -D $tmpDir/heads > $tmpDir/classicPkgs
  if [ "$U7S_RPMRegistryClassic" != "$U7S_RPMRegistryNoarch" ]
  then
    curl --connect-timeout 600 -sk ${U7S_RPMRegistryNoarch}/  > $tmpDir/noarchPkgs
  fi
  set -- $(grep Content-Type: $tmpDir/heads)
  contentType=$(echo $2 | tr -d '\r\n')
  for kubeVersion in $kubeVersions
  do
    kubeMinorVersion=$(getMinorVersion $kubeVersion)
    if [ "$contentType" = 'application/json' ]
    then
      listClassicRPMS+=' '$(jq -r '.[] | select(.name[0:15]=="kubernetes'$kubeMinorVersion'-") | .name' $tmpDir/classicPkgs)
      listClassicRPMS+=' '$(jq -r '.[] | select(.name[0:10]=="cri-o'$kubeMinorVersion'-") | .name' $tmpDir/classicPkgs)
    else
      listClassicRPMS+=' '$(grep kubernetes${kubeMinorVersion} $tmpDir/classicPkgs | sed -e 's|</a>.*||' -e 's|<a href=.*>||')
      listClassicRPMS+=' '$(grep cri-o${kubeMinorVersion} $tmpDir/classicPkgs | sed -e 's|</a>.*||' -e 's|<a href=.*>||')
    fi

    if [ "$U7S_RPMRegistryClassic" != "$U7S_RPMRegistryNoarch" ]
    then
      if [ "$contentType" = 'application/json' ]
      then
        listNoarchRPMS+=' '$(jq -r '.[] | select(.name[0:15]=="kubernetes'$kubeMinorVersion'-") | .name' tmpDir/noarchPkgs)
      else
        listClassicRPMS+=' '$(grep kubernetes${kubeMinorVersion} $tmpDir/noarchPkgs | sed -e 's|</a>.*||' -e 's|<a href=.*>||')
      fi
    fi
  done
  pushd $tmpDir
  for pkg in $listClassicRPMS
  do
    echo "$(gettext 'Loading rpm package ') $pkg"
    curl -sk "$U7S_RPMRegistryClassic/$pkg" -o "$pkg"
  done
  for pkg in $listNoarchRPMS
  do
    echo "$(gettext 'Loading rpm package ') $pkg"
    curl -sk "$U7S_RPMRegistryNoarch/$pkg" -o "$pkg"
  done
#   rm -f $tmpDir/heads $tmpDir/noarchPkgs $tmpDir/classicPkgs
  popd
  echo $tmpDir $tmpDir/classicPkgs
}


export U7S_REGISTRY='registry.local'
export kubeVersion=$(getCurrentKubeVersion)
export kubeMinorVersion=$(getMinorVersion $kubeVersion)
export prevKubeMinorVersion=$(getPrevMinorVersion $kubeMinorVersion)
nextKubeVersions=$(getNextKubeVersions $kubeMinorVersion)
echo "kubeVersion $kubeVersion
kubeMinorVersion=$kubeMinorVersion
prevKubeMinorVersion=$prevKubeMinorVersion
nextKubeVersions=$nextKubeVersions
"

if [ -z "$nextKubeVersions" ]
then
    echo "$(gettext 'There are no new versions for the current version') $kubeVersion $(gettext 'of kubernetes on the registry') $U7S_REGISTRY" 2>&1
  exit 1
fi

prevKubeMinorVersion=$kubeMinorVersion

loadRpmPackages $nextKubeVersions

for kubeVersion in $nextKubeVersions
do
  kubeMinorVersion=$(getMinorVersion $kubeVersion)
  echo -ne "\n\n---------------------------\n$(gettext 'Upgrading from kubernet version') $prevKubeMinorVersion $(gettext 'to version' $kubeVersion)\n"
done
