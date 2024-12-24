#!/bin/sh
source podsec-k8s-upgrade-functions

export TEXTDOMAINDIR='/usr/share/locale'
export TEXTDOMAIN='podsec-k8s-upgrade'

# MAIN

if [ $# -gt 2 -o $# -eq 0 ]
then
  echo "$(gettext 'Format:')"
  echo -ne "\t$0 masterNodeName [toMinorVersion]\n"
  exit 1
fi
masterNodeName=$1
export nodeNames=$(kubectl  get nodes -o json | jq -r '.items[].metadata.name')
U7S_MasterNodeName=''
U7S_SlaveNodeNames=''
for nodeName in $nodeNames
do
  if [ "$nodeName" = "$masterNodeName" ]
  then
    U7S_MasterNodeName=$masterNodeName
  else
    U7S_SlaveNodeNames+=" $nodeName"
  fi
done
if [ -z "$U7S_MasterNodeName" ]
then
  echo "$(gettext 'Master node') $masterNodeName $(gettext 'absent in cluster nodes'): $nodeNames"
  exit 1
fi
export U7S_HOSTNAME=$(hostname)


toMinorVersion=''
if [ $# -eq 2 ]
then
  toMinorVersion=$2
fi
export isControlPlane=$(kubectl get nodes -o yaml |
  yq '.items[] |
  select(.metadata.name=="'$U7S_HOSTNAME'") |
  .metadata.labels |
  has("node-role.kubernetes.io/control-plane")')
if [ -z "$isControlPlane" ]
then
  echo "$(gettext 'The node with name') $U7S_HOSTNAME $(gettext 'cannot be determined. Make sure the node name output by hostname matches the node name listed by kubectl get nodes'.)"
  exit 1
fi
export flannelImage=$(kubectl get  -n kube-flannel daemonset.apps/kube-flannel-ds  -o json |
  jq  -r '.spec.template.spec.containers[0].image')
ifs=$IFS; IFS=:; set -- $flannelImage; IFS=$ifs
export flannelTag=$2

export U7S_REGISTRY=$(getRegistry)
# export U7S_PLATFORM_1_26='k8s-c10f1'
export U7S_PLATFORM=$(getPlatform)
export U7S_REGISTRYPATH="$U7S_REGISTRY/$U7S_PLATFORM"
export kubeVersion=$(getCurrentKubeadmVersion)
export kubeMinorVersion=$(getMinorVersion $kubeVersion)
nextKubeVersions=$(getNextKubeVersions $kubeMinorVersion "$toMinorVersion")
prevKubeMinorVersions=$(getPrevKubeMinorVersions $kubeMinorVersion)
if [ -n "$toMinorVersion" -a -z "$(echo $nextKubeVersions | tr ' ' '\n' | egrep ^$toMinorVersion)" ]
then
  echo "$(gettext 'The specified final minor version') $toMinorVersion $(gettext 'is not available in the image repository.')"
  exit 1
fi

chown u7s-admin:u7s-admin  /usr/libexec/cni

export prevImages=$(
  machinectl shell u7s-admin@ /usr/bin/kubeadm config images list --image-repository=$U7S_REGISTRY |
  grep $U7S_REGISTRY |
  tr -d '\r'
)
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

TMPCMDFile="/tmp/cmd_$$.sh"
echo '
#!/bin/sh
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

for configFile in $(grep -rl c10f1 /var/lib/u7s-admin/.config/)
do
  sed -i -e 's/c10f1/c10f2/g' $configFile
done

for shellFile in $(grep -rl c10f1 /usr/libexec/podsec/u7s/bin/)
do
  sed -i -e 's/c10f1/c10f2/g' $shellFile
done

for kubeVersion in $nextKubeVersions
do
  kubeMinorVersion=$(getMinorVersion $kubeVersion)
  echo -ne "\n\n---------------------------\n$(gettext 'Upgrading from kubernet version') $prevKubeMinorVersion $(gettext 'to version' $kubeVersion)\n"
  echo "$(gettext 'Installing kubeadm and kubelet for next kubernetes version ') $kubeVersion"
  rpm -i --replacefiles --nodeps $U7S_rpmDir/kubernetes${kubeMinorVersion}-kubeadm_${kubeMinorVersion}.*.rpm
  rpm -i --replacefiles --nodeps $U7S_rpmDir/kubernetes${kubeMinorVersion}-kubelet_${kubeMinorVersion}.*.rpm
  kubeadmVersion=$(getCurrentKubeadmVersion)
  kubeadmMinorVersion=$(getMinorVersion $kubeadmVersion)
  if [ "$kubeMinorVersion" != "$kubeadmMinorVersion" ]
  then
    echo "$(gettext 'kubeadm minor version') $kubeadmMinorVersion $(gettext 'does not match target minor version') $kubeMinorVersion"
    exit 1
  fi

  if [ "$U7S_MasterNodeName" = "U7S_HOSTNAME" ] #MASTER NODE
  then
    echo "$(gettext 'Get registry path in current cluster')"
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
  fi

  echo "$(gettext 'Loading kubernetes images for version') $kubeVersion"
    machinectl shell u7s-admin@ \
    /usr/libexec/podsec/u7s/bin/nsenter_u7s \
      /usr/bin/kubeadm -v 9  config images pull \
        --image-repository=$U7S_REGISTRYPATH \
        --kubernetes-version=v${kubeVersion}


  if [ "$U7S_MasterNodeName" = "U7S_HOSTNAME" ] #MASTER NODE
  then
    if [[ "$kubeMinorVersion" > '1.26' ]]
    then
      currentFlannelVersion=$(getCurrentFlannelVersion)
      toFlannelVersion='1.25.1'
      if [ "$currentFlannelVersion" != "$toFlannelVersion" ]
      then
        echo "$(gettext 'Upgrads flannel from') $currentFlannelVersion $(gettext 'to') $toFlannelVersion"
        echo "$(gettext 'Remove rpm package cni-plugin-flannel-1.1.2')"
        kubectl -n kube-flannel delete daemonset.apps/kube-flannel-ds
        rpm -e --replacefiles --nodeps  cni-plugin-flannel-1.1.2
        chown u7s-admin:u7s-admin -R /usr/libexec/cni/
        rm -f /usr/libexec/cni/flannel
        curl http://sigstore.local:81/manifests/kube-flannel/0/25/1/kube-flannel.yml |
        sed -e "s|docker.io/flannel|${U7S_REGISTRY}/${U7S_PLATFORM}|g" |
        kubectl apply -f -
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
  fi

  if [ "$U7S_MasterNodeName" = "U7S_HOSTNAME" ] #MASTER NODE
  then
    sameVesions=''
    while [ -z "$sameVesions" ]
    do
      sameVesions='yes'
      for slaveNode in $U7S_SlaveNodeNames
      do
        slaveKubeProxyMinorVersion=$(getKubeProxyMinorVerion $slaveNode)
        deltaMinorVersions=$(getDeltaMinorVersions "$kubeMinorVersion" "$slaveKubeProxyMinorVersion")
        if [ "$deltaMinorVersions" -eq 1 ]; then :;
        elif [ "$deltaMinorVersions" -gt 1 ]
        then
          sameVesions=''
          if [ "$deltaMinorVersions" -gt 2 ]
          then
            echo "$(gettext 'The deploying minor version') $kubeMinorVersion $(gettext 'of the master node') $U7S_MasterNodeName $(gettext 'is more than 1 higher, than the node') $slaveNode $(gettext 'version') $slaveKubeProxyMinorVersion"
            echo "$(gettext 'There may be problems upgrating the cluster.')"
          fi
          echo "$(gettext 'Waiting for the deployed minor version') $slaveKubeProxyMinorVersion $(gettext 'of the node') $slaveNode $(gettext 'to be updated to') $kubeMinorVersion"
          sleep 10
          break
        elif [ "$deltaMinorVersions" -eq 0 ]
        then
          echo "$(gettext 'The deploying minor version') $kubeMinorVersion $(gettext 'of the master node') $U7S_MasterNodeName $(gettext 'is equal the node') $slaveNode $(gettext 'version') $slaveKubeProxyMinorVersion"
        else
          echo "$(gettext 'The deploying minor version') $kubeMinorVersion $(gettext 'of the master node') $U7S_MasterNodeName $(gettext 'is more than 1 lower, than the node') $slaveNode $(gettext 'version') $slaveKubeProxyMinorVersion"
          echo "$(gettext 'There may be problems upgrating the cluster.')"
        fi
      done
    done
  else # WORKER OR ControlPlane Node
    masterKubeProxyMinorVersion=$(getKubeProxyMinorVerion $U7S_MasterNodeName)
    deltaMinorVersions=$(getDeltaMinorVersions "$kubeMinorVersion" "$masterKubeProxyMinorVersion")
    while [ "$deltaMinorVersions" -gt 0 ]
    do
      if [ "$deltaMinorVersions" -gt 1 ]
      then
        echo "$(gettext 'The deploying minor version') $kubeMinorVersion $(gettext 'of the  node') $U7S_HOSTNAME $(gettext 'is more than 1 higher, than the master node') $U7S_MasterNodeName $(gettext 'version') $masterKubeProxyMinorVersion"
        echo "$(gettext 'There may be problems upgrating the cluster.')"
      fi
      echo "$(gettext 'Waiting for the deployed version') $masterKubeProxyMinorVersion $(gettext 'of the master node') $U7S_MasterNodeName $(gettext 'to be updated to') $kubeMinorVersion"
      sleep 10
      masterKubeProxyMinorVersion=$(getKubeProxyMinorVerion $U7S_MasterNodeName)
      deltaMinorVersions=$(getDeltaMinorVersions "$kubeMinorVersion" "$masterKubeProxyMinorVersion")
    done
    if [ "$deltaMinorVersions" -lt 0 ]
    then
      echo "$(gettext 'The deploying minor version') $kubeMinorVersion $(gettext 'of the  node') $U7S_HOSTNAME $(gettext 'is more than 1 higher, than the master node') $U7S_MasterNodeName $(gettext 'version') $masterKubeProxyMinorVersion"
      echo "$(gettext 'There may be problems upgrating the cluster.')"
    fi
  fi

  cordonedNodes=$(listCordonedNodes)
  while [ -n "$cordonedNodes" ]
  do
    echo "$(gettext 'Waiting for uncordon nodes:') $cordonedNodes"
    sleep 5
    cordonedNodes=$(listCordonedNodes)
  done

  echo -ne "$(gettext 'Cordon node') $HOSTNAME"
  kubectl cordon $HOSTNAME

  echo "$(gettext 'Updating cluster node services to version') $kubeVersion"
  echo "$(gettext 'Wait several minutes...')"
  machinectl shell u7s-admin@ \
    /usr/libexec/podsec/u7s/bin/nsenter_u7s \
      /usr/bin/kubeadm upgrade  apply -y ${kubeVersion}


  if [[ "$kubeMinorVersion" > '1.29' ]]
  then
    echo -ne "$(gettext 'Remove node pods and containers')"
    kubectl drain $HOSTNAME --ignore-daemonsets --delete-emptydir-data
    while killall kubelet 2>/dev/null; do sleep 1; done
    echo "$(gettext 'Remove all pods and containers')"
    machinectl shell u7s-admin@ /usr/libexec/podsec/u7s/bin/nsenter_u7s sh -x $TMPCMDFile
  fi
# exit
  systemctl stop u7s

  if [[ "$kubeMinorVersion" > '1.30' ]]
  then
    for configFile in $(grep -rl 'pause:' /var/lib/u7s-admin/.config/)
    do
      sed -i -e 's/pause:3.9/pause:3.10/g' $configFile
    done

    for shellFile in $(grep -rl 'pause:' /usr/libexec/podsec/u7s/bin/)
    do
      sed -i -e 's/pause:3.9/pause:3.10/g' $shellFile
    done
  fi

#   if [[ "$kubeMinorVersion" = '1.27' ]]
#   then
  listPrevRPMs=$(rpm -qa | grep 'cri-o
cri-tools
kubernetes' |
  grep "${prevKubeMinorVersion}")
  echo "$(gettext 'Removing rpm packeges') $listPrevRPMs $(gettext 'of previous kubernetes version ') ${prevKubeMinorVersion}"
  rpm -e --nodeps $listPrevRPMs
#   fi

#   pushd /var/sigstore/rpms/
  listNewRPMS="
    kubernetes${kubeMinorVersion}-client
    kubernetes${kubeMinorVersion}-common
    kubernetes${kubeMinorVersion}-crio
    kubernetes${kubeMinorVersion}-master
    kubernetes${kubeMinorVersion}-node
    cri-o${kubeMinorVersion}
    cri-tools${kubeMinorVersion}
    cni-plugin-flannel
    "
  if [[ "$kubeMinorVersion" > '1.28' ]]
  then
    listNewRPMS+="
    cni-plugins
    "
  fi
  if [[ "$kubeMinorVersion" > '1.29' ]]
  then
    listNewRPMS+="
    crun
    libcrun
    runc
    "
  fi
  echo "$(gettext 'Installing rpm packeges') $listNewRPMS $(gettext 'of new kubernetes version ') ${kubeMinorVersion}"
  apt-get install -y $listNewRPMS

  echo -ne "$(gettext 'Restart node services')"
  sleep 1
  systemctl start u7s
  machinectl shell u7s-admin@ /usr/bin/systemctl --user start kubelet


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

#   if [ -z "$(getCurrentKubeAPIVersion)" ]
#   then
#     echo "$(gettext 'kubernetes services down')"
#     echo "$(gettext 'Exit')"
#     exit 1
#   fi

  # Find and remove old images
#   oldImageIds=$(machinectl shell u7s-admin@ /usr/libexec/podsec/u7s/bin/nsenter_u7s /usr/bin/crictl images |
#     grep $(echo $prevKubeMinorVersions | tr ' ' '\n') |
#     while read image tag id size; do echo $id; done
#     )
#   oldImageIds+=$(machinectl shell u7s-admin@ /usr/libexec/podsec/u7s/bin/nsenter_u7s /usr/bin/crictl images |
#     grep /coredns | sort -V -k 2 | head -n -1 |
#     while read image tag id size; do echo $id; done
#     )
#   oldImageIds+=$(machinectl shell u7s-admin@ /usr/libexec/podsec/u7s/bin/nsenter_u7s /usr/bin/crictl images |
#     grep /pause | sort -V -k 2 | head -n -1 |
#     while read image tag id size; do echo $id; done
#     )
#   oldImageIds+=$(machinectl shell u7s-admin@ /usr/libexec/podsec/u7s/bin/nsenter_u7s /usr/bin/crictl images |
#     grep /etcd | sort -V -k 2 | head -n -1 |
#     while read image tag id size; do echo $id; done
#     )
#   machinectl shell u7s-admin@ /usr/libexec/podsec/u7s/bin/nsenter_u7s /usr/bin/crictl rmi $oldImageIds
  prevKubeMinorVersion=$kubeMinorVersion
  prevKubeMinorVersions+=" $prevKubeMinorVersion"
done



