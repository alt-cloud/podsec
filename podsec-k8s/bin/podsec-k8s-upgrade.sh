#!/bin/sh

export TEXTDOMAINDIR='/usr/share/locale'
export TEXTDOMAIN='podsec-k8s'

function getCurrentFlannelVersion() {
  ret=''
  flannelImage=$(kubectl -n kube-flannel get daemonset.apps/kube-flannel-ds -o yaml |
    yq '.spec.template.spec.containers[0].image')
  if [ -n "$flannelImage" ]
  then
    flannelImage=$(basename $flannelImage)
    ifs=$IFS; IFS=:; set -- $flannelImage; IFS=$ifs; ret=${2:1}
  fi
  echo -ne $ret
}

function getNodeCurrentKubeletVersion() {
  ret=''
  nodeKubeletVersion=$(kubectl get nodes -o json |
    jq -r '.items[] | select(.metadata.name=="'$U7S_HOSTNAME'") | .status.nodeInfo.kubeletVersion')
  if [ -n "$nodeKubeletVersion" ]
  then
    ret=${nodeKubeletVersion:1}
  fi
  echo -ne $ret
}

function getCurrentKubeAPIVersion() {
  ret=''
  kubeapiVersion=$(kubectl -n kube-system get pods -o json |
    jq -r '.items[] | select(.metadata.name=="kube-apiserver-'${U7S_HOSTNAME}'") | .spec.containers[0].image')
  if [ -n "$kubeapiVersion" ]
  then
    kubeapiVersion=$(basename $kubeapiVersion)
    ifs=$IFS; IFS=:; set -- $kubeapiVersion; IFS=$ifs; ret=${2:1}
  fi
  echo -ne $ret
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
  toMinorVersion=$2
  if [ $U7S_REGISTRY == 'registry.local' ]
  then
    protocol='http'
  else
    protocol='https'
  fi
  kubeVersions=$(curl -sk $protocol://$U7S_REGISTRY/v2/${U7S_PLATFORM}/kube-apiserver/tags/list | jq -r .tags[] | sort -V)
  ret=''
  lastMinorKubeVersion=$curMinorKubeVersion
  lastPatchKubeVersion=''
  for kubeVersion in $kubeVersions
  do
    if [ "${kubeVersion:0:1}" != 'v' ]; then continue; fi
    kubeVersion=${kubeVersion:1}
    curMinor=$(getMinorVersion $kubeVersion)
    if [[ "$curMinor" > "$curMinorKubeVersion" ]]
    then
      if [ -n "$lastPatchKubeVersion" -a "$curMinor" != "$lastMinorKubeVersion" ]
      then
        ret+="$lastPatchKubeVersion\n"
      fi
    else
      continue
    fi
    if [ -n "${toMinorVersion}" ]
    then
      if [[ "${kubeVersion:0:${#toMinorVersion}}" > "${toMinorVersion}" ]]
      then
        break
      fi
    fi
    lastPatchKubeVersion=$kubeVersion
    lastMinorKubeVersion=$curMinor
  done
  ret+="$lastPatchKubeVersion\n"
  ret="$(echo -ne "$ret" | sort -u)"
  echo $ret
}

function setRPMRegistries() {
  if [ "$U7S_REGISTRY" = 'registry.local' ]
  then
    apt-repo add 'rpm http://sigstore.local:81/kubernetes_upgrade x86_64 main'
    export U7S_RPMRegistryClassic='http://sigstore.local:81/kubernetes_upgrade/x86_64/RPMS.main/'
    export U7S_RPMRegistryNoarch='http://sigstore.local:81/kubernetes_upgrade/x86_64/RPMS.main/'
  elif [ "${U7S_PLATFORM:0:8}" = 'k8s-c10f' ]
  then
    apt-repo add 'rpm [cert8] http://update.altsp.su/pub/distributions/ALTLinux c10f/branch/x86_64-i586 classic'
    apt-repo add 'rpm [cert8] http://update.altsp.su/pub/distributions/ALTLinux c10f/branch/noarch classic'
    export U7S_RPMRegistryClassic="http://update.altsp.su/${U7S_PLATFORM:4}/branch/x86_64/RPMS.classic"
    export U7S_RPMRegistryNoarch="http://update.altsp.su/${U7S_PLATFORM:4}/branch/noarch/RPMS.classic"
  fi
}

function loadRpmPackages() {
  kubeVersions="$*"
  echo "$(gettext 'Loading RPM packages for') $kubeVersions"
  export U7S_rpmDir='/tmp/RPMS'
  mkdir -p $U7S_rpmDir
  rm -f $U7S_rpmDir/*
  listClassicRPMS=''
  listNoarchRPMS=''
  setRPMRegistries
  curl --connect-timeout 600 -sk ${U7S_RPMRegistryClassic}/ -D $U7S_rpmDir/heads > $U7S_rpmDir/classicPkgs
  if [ "$U7S_RPMRegistryClassic" != "$U7S_RPMRegistryNoarch" ]
  then
    curl --connect-timeout 600 -sk ${U7S_RPMRegistryNoarch}/  > $U7S_rpmDir/noarchPkgs
  fi
  set -- $(grep Content-Type: $U7S_rpmDir/heads)
  contentType=$(echo $2 | tr -d '\r\n')
  for kubeVersion in $kubeVersions
  do
    kubeMinorVersion=$(getMinorVersion $kubeVersion)
    if [ "$contentType" = 'application/json' ]
    then
      listClassicRPMS+=' '$(jq -r '.[] | select(.name[0:15]=="kubernetes'$kubeMinorVersion'-") | .name' $U7S_rpmDir/classicPkgs)
      listClassicRPMS+=' '$(jq -r '.[] | select(.name[0:10]=="cri-o'$kubeMinorVersion'-") | .name' $U7S_rpmDir/classicPkgs)
      listClassicRPMS+=' '$(jq -r '.[] | select(.name[0:10]=="cri-tools'$kubeMinorVersion'-") | .name' $U7S_rpmDir/classicPkgs)
    else
      listClassicRPMS+=' '$(grep kubernetes${kubeMinorVersion} $U7S_rpmDir/classicPkgs | sed -e 's|</a>.*||' -e 's|<a href=.*>||')
      listClassicRPMS+=' '$(grep cri-o${kubeMinorVersion} $U7S_rpmDir/classicPkgs | sed -e 's|</a>.*||' -e 's|<a href=.*>||')
      listClassicRPMS+=' '$(grep cri-tools${kubeMinorVersion} $U7S_rpmDir/classicPkgs | sed -e 's|</a>.*||' -e 's|<a href=.*>||')
    fi

    if [ "$U7S_RPMRegistryClassic" != "$U7S_RPMRegistryNoarch" ]
    then
      if [ "$contentType" = 'application/json' ]
      then
        listNoarchRPMS+=' '$(jq -r '.[] | select(.name[0:15]=="kubernetes'$kubeMinorVersion'-") | .name' U7S_rpmDir/noarchPkgs)
      else
        listClassicRPMS+=' '$(grep kubernetes${kubeMinorVersion} $U7S_rpmDir/noarchPkgs | sed -e 's|</a>.*||' -e 's|<a href=.*>||')
      fi
    fi
  done
  pushd $U7S_rpmDir
  for pkg in $listClassicRPMS
  do
    echo "$(gettext 'Loading rpm package ') $pkg" >&2
    curl -sk "$U7S_RPMRegistryClassic/$pkg" -o "$pkg"
  done
  for pkg in $listNoarchRPMS
  do
    echo "$(gettext 'Loading rpm package ') $pkg"
    curl -sk "$U7S_RPMRegistryNoarch/$pkg" -o "$pkg" >&2
  done
#   rm -f $U7S_rpmDir/heads $U7S_rpmDir/noarchPkgs $U7S_rpmDir/classicPkgs
  popd
  echo $U7S_rpmDir
}

# MAIN

if [ $# -gt 1 ]
then
  echo "$(gettext 'Format:')"
  echo -ne "\t$0 [toMinorVersion]\n"
  exit 1
fi
toMinorVersion=''
if [ $# -eq 1 ]
then
  toMinorVersion=$1
fi
export U7S_HOSTNAME=$(hostname)
export U7S_REGISTRY='registry.local'
# export U7S_PLATFORM_1_26='k8s-c10f1'
export U7S_PLATFORM='k8s-c10f2'
export U7S_REGISTRYPATH="$U7S_REGISTRY/$U7S_PLATFORM"
export kubeVersion=$(getCurrentKubeAPIVersion)
export kubeMinorVersion=$(getMinorVersion $kubeVersion)
nextKubeVersions=$(getNextKubeVersions $kubeMinorVersion "$toMinorVersion")
if [ -n "$toMinorVersion" -a -z "$(echo $nextKubeVersions | tr ' ' '\n' | egrep ^$toMinorVersion)" ]
then
  echo "$(gettext 'The specified final minor version') $toMinorVersion $(gettext 'is not available in the image repository.')"
  exit 1
fi

export prevImages=$(machinectl shell u7s-admin@ /usr/bin/kubeadm config images list --image-repository=$U7S_REGISTRY | grep $U7S_REGISTRY | tr -d '\r')
echo "kubeVersion $kubeVersion
kubeMinorVersion=$kubeMinorVersion
nextKubeVersions=$nextKubeVersions
prevImages=$prevImages
"
# exit

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
  echo "$(gettext 'Installing kubeadm and kubelet for next kubernetes version ') $kubeVersion"
  rpm -i --replacefiles --nodeps $U7S_rpmDir/kubernetes${kubeMinorVersion}-kubeadm-${kubeMinorVersion}.*.rpm
  rpm -i --replacefiles --nodeps $U7S_rpmDir/kubernetes${kubeMinorVersion}-kubelet-${kubeMinorVersion}.*.rpm
  kubeadmVersion=$(kubeadm version -o json | jq -r .clientVersion.gitVersion)
  kubeadmVersion=${kubeadmVersion:1}
  kubeadmMinorVersion=$(getMinorVersion $kubeadmVersion)
  if [ "$kubeMinorVersion" != "$kubeadmMinorVersion" ]
  then
    echo "$(gettext 'kubeadm minor version') $kubeadmMinorVersion $(gettext 'does not match target minor version') $kubeMinorVersion"
    exit 1
  fi
  eval clusterConfiguration=$(kubectl get -n kube-system configmaps kubeadm-config -o yaml | yq '.data.ClusterConfiguration')
  CURRENT_REGISTRYPATH=$(echo -e $clusterConfiguration | yq -r .imageRepository)

  if [ "$CURRENT_REGISTRYPATH" != "$U7S_REGISTRYPATH" ]
  then
    echo "$(gettext 'Current platform does') $CURRENT_REGISTRYPATH $(gettext 'not match target') $U7S_REGISTRYPATH"
    echo "$(gettext 'Update kubeadm-config to') $U7S_REGISTRYPATH"
    kubectl get -n kube-system configmaps kubeadm-config -o yaml |
    sed  -e "s|${CURRENT_REGISTRYPATH}|${U7S_REGISTRYPATH}|" |
    kubectl apply -n kube-system  -f -
    if [ -f "~u7s-admin/.config/usernetes/init.yaml" ]
    then
      machinectl shell u7s-admin@ /bin/sed -i -e "s|${CURRENT_REGISTRYPATH}|${U7S_REGISTRYPATH}|" ~u7s-admin/.config/usernetes/init.yaml
    fi
    if [ -f "~u7s-admin/.config/usernetes/join.yaml" ]
    then
      machinectl shell u7s-admin@ /bin/sed -i -e "s|${CURRENT_REGISTRYPATH}|${U7S_REGISTRYPATH}|" ~u7s-admin/.config/usernetes/join.yaml
    fi
  fi

  echo "$(gettext 'Loading kubernetes images for version') $kubeVersion"
    machinectl shell u7s-admin@ \
    /usr/libexec/podsec/u7s/bin/nsenter_u7s \
      /usr/bin/kubeadm -v 9  config images pull \
        --image-repository=$U7S_REGISTRYPATH \
        --kubernetes-version=v${kubeVersion}

  if [[ "$kubeMinorVersion" > '1.26' ]]
  then
    currentFlannelVersion=$(getCurrentFlannelVersion)
    toFlannelVersion='1.25.1'
    if [ "$currentFlannelVersion" != "$toFlannelVersion" ]
    then
      echo "$(gettext 'Upgrads flannel from') $currentFlannelVersion $(gettext 'to') $toFlannelVersion"
      echo "$(gettext 'Remove rpm package cni-plugin-flannel-1.      kubectl -n kube-flannel delete daemonset.apps/kube-flannel-ds
      kubectl apply -f http://sigstore.local:81/manifests/kube-flannel/0/25/1/kube-flannel.yml1.2')"
      rpm -e --replacefiles --nodeps  cni-plugin-flannel-1.1.2
      chown u7s-admin:u7s-admin -R /usr/libexec/cni/
      rm -f /usr/libexec/cni/flannel

      while :;
      do
        numberReady=$(kubectl  -n kube-flannel get daemonset.apps/kube-flannel-ds -o json | jq -r '.status.numberReady')
        if [ "$numberReady" -gt 0 ] 2>/dev/null
        then
          break
        fi
        echo "$(gettext 'Waiting for service') kube-flannel:0.25.1 $(gettext 'to be restored')"
        sleep 1
      done
    fi
  fi
  echo "$(gettext 'Updating cluster node services to version') $kubeVersion"
  echo "$(gettext 'Wait several minutes...')"
  machinectl shell u7s-admin@ \
    /usr/libexec/podsec/u7s/bin/nsenter_u7s \
      /usr/bin/kubeadm upgrade  apply -y ${kubeVersion}

  echo -ne "$(gettext 'Cordon node, remove node pods and containers')"
  kubectl cordon $HOSTNAME
  kubectl drain $HOSTNAME --ignore-daemonsets --delete-emptydir-data
  while killall kubelet 2>/dev/null; do sleep 1; done
  TMPCMDFile="/tmp/cmd_$$.sh"
  echo '
while [ "$(crictl ps -qa | wc -l)" -ne 0 ]
do
  for p in $(crictl pods -q);
  do
    if [ "$(crictl inspectp $p | jq -r .status.linux.namespaces.options.network)" != "NODE" ];
    then
      crictl rmp -f $p;
    fi;
  done
  crictl rmp -fa
  sleep 1
done
' > $TMPCMDFile

  machinectl shell u7s-admin@ /usr/libexec/podsec/u7s/bin/nsenter_u7s sh -x $TMPCMDFile
# exit
    systemctl stop u7s

  listPrevRPMs=$(rpm -qa | grep 'cri-o
cri-tools
kubernetes')


  echo "$(gettext 'Removing rpm packeges') $listPrevRPMs $(gettext 'of previous kubernetes version ') ${prevKubeMinorVersion}"
  rpm -e --nodeps $listPrevRPMs

  pushd $U7S_rpmDir
#   pushd /var/sigstore/rpms/
  listNewRPMS=$(echo kubernetes${kubeMinorVersion}-* \
    cri-o${kubeMinorVersion}-* \
    cri-tools${kubeMinorVersion}-*\
    cni-plugin-flannel-1.*\
    cni-plugins-* \
    )
  if [[ $curMinorKubeVersion -gt '1.29' ]]
  then
    listNewRPMS+=$(echo crun-*)
  fi
  echo "$(gettext 'Installing rpm packeges') $listNewRPMS $(gettext 'of new kubernetes version ') ${kubeMinorVersion}"
  apt-get install -y $listNewRPMS
#   for pkg in cri-o${kubeMinorVersion}-* cri-tools${kubeMinorVersion}-*
#   do
#     echo "$(gettext 'Installing') $pkg $(gettext 'for next kubernetes version ') $kubeVersion"
#     rpm -i --replacefiles --nodeps $pkg
#   done
  popd

  echo -ne "$(gettext 'Restart node services')"
  sleep 1
  systemctl start u7s
  machinectl shell u7s-admin@ /usr/bin/systemctl --user start kubelet

  echo -ne "$(gettext 'Waiting for kubeapi node services to come up') ."
  sleep 1
  while :;
  do
    currentKubeAPIVersion=$(getCurrentKubeAPIVersion)
    currentKubeAPIVersion=$(getMinorVersion $currentKubeAPIVersion)
    if [ -n "$currentKubeAPIVersion" ]
    then
      if [ "$currentKubeAPIVersion" != "${kubeMinorVersion}" ]
      then
        echo "$(gettext 'The kubeapi version') $currentKubeAPIVersion $(gettext 'on the node') $U7S_HOSTNAME $(gettext 'does not match the target version') $kubeMinorVersion" >&2
      else
        break
      fi
    fi
    echo -ne .
    sleep 1
  done

  echo -ne "$(gettext 'Waiting for kubelet node services to come up') ."
  while :;
  do
    nodeCurrentKubeletVersion=$(getNodeCurrentKubeletVersion)
    nodeCurrentKubeletVersion=$(getMinorVersion $nodeCurrentKubeletVersion)
    if [ -n "$nodeCurrentKubeletVersion" ]
    then
      if [ "$nodeCurrentKubeletVersion" != "${kubeMinorVersion}" ]
      then
        echo -ne "\n$(gettext 'The kubelet version') $nodeCurrentKubeletVersion $(gettext 'on the node') $U7S_HOSTNAME $(gettext 'does not match the target version') $kubeMinorVersion\n" >&2
      else
        break
      fi
    fi
    echo -ne .
    sleep 1
  done

  kubectl uncordon $HOSTNAME

#   prevImages=$(machinectl shell u7s-admin@ /usr/bin/kubeadm config images list --image-repository=$U7S_REGISTRY 2>/dev/null)
#   machinectl shell u7s-admin@ /usr/bin/crictl rmi $prevImages
  if [ -z "$(getCurrentKubeAPIVersion)" ]
  then
    echo "$(gettext 'kubernetes services down')"
    echo "$(gettext 'Exit')"
    exit 1
  fi
  prevKubeMinorVersion=$kubeMinorVersion
done
