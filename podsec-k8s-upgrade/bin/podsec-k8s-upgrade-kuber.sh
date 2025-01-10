#!/bin/sh
source podsec-k8s-upgrade-functions

export TEXTDOMAINDIR='/usr/share/locale'
export TEXTDOMAIN='podsec-k8s-upgrade'

# MAIN

if [ $# -gt 2 -o $# -eq 0 ]
then
  echo "$(gettext 'Format:')" >&2
  echo -ne "\t$0 masterNodeName [toMinorVersion]\n" >&2
  exit 1
fi
masterNodeName=$1
export U7S_HOSTNAME=$(hostname)
NodesJSON="$(kubectl get nodes  -o json)"
export nodeNames=$(echo $NodesJSON | jq -r '.items[].metadata.name')
controlPlaneNames=$(echo $NodesJSON | jq '.items[].metadata | select(.labels."node-role.kubernetes.io/control-plane"!=null)|.name')
export U7s_WorkerNames=$(echo $NodesJSON | jq '.items[].metadata | select(.labels."node-role.kubernetes.io/control-plane"==null)| .name')
export U7S_NodeRole=''
export U7S_MasterNodeName=''
export U7S_SlaveNodeNames=''
for nodeName in $nodeNames
do
  if [ "$nodeName" = "$masterNodeName" ]
  then
    U7S_MasterNodeName=$masterNodeName
  else
    U7S_SlaveNodeNames+=" $nodeName"
  fi
  if [ $nodeName = $U7S_HOSTNAME ]
  then
    U7S_NodeRole='node'
  fi
done

if [ -z "$U7S_MasterNodeName" ]
then
  echo "$(gettext 'Master node') $masterNodeName $(gettext 'absent in cluster nodes'): $nodeNames"  >&2
  exit 1
fi

if [ -z "$U7S_NodeRole" ]
then
  echo "$(gettext 'Current node') $U7S_HOSTNAME $(gettext 'absent in cluster nodes'): $nodeNames"  >&2
  exit 1
fi


export U7S_ControlPlaneNames=''
for nodeName in $controlPlaneNames
do
  if [ "$nodeName" != "$masterNodeName" ]
  then
    U7S_ControlPlaneNames+=" $nodeName"
    U7S_NodeRole='controlplane'
  fi
done

if [ $U7S_NodeRole = 'node' ]
then
  U7S_NodeRole='worker'
fi

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
  echo "$(gettext 'The node with name') $U7S_HOSTNAME $(gettext 'cannot be determined. Make sure the node name output by hostname matches the node name listed by kubectl get nodes'.)" >&2
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
  echo "$(gettext 'The specified final minor version') $toMinorVersion $(gettext 'is not available in the image repository.')" >&2
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

if [ "$U7S_NodeRole" = 'controlplane' ]
then
  echo $(gettext 'Untaint node') $HOSTNAME >&2
  kubectl taint nodes $HOSTNAME node-role.kubernetes.io/control-plane:NoSchedule-
fi

for kubeVersion in $nextKubeVersions
do
  kubeMinorVersion=$(getMinorVersion $kubeVersion)
  echo -ne "\n\n---------------------------\n" \
    "$(gettext 'Upgrading from kubernet version') $prevKubeMinorVersion" \
    "$(gettext 'to version') $kubeVersion\n" >&2
  echo "$(gettext 'Installing kubeadm  for next kubernetes version ') $kubeVersion" >&2
  rpm -i --replacefiles --nodeps \
    $U7S_rpmDir/kubernetes${kubeMinorVersion}-kubeadm_${kubeMinorVersion}.*.rpm 2>/dev/null
  if [[ "$kubeMinorVersion" != '1.31' ]]
  then
    echo "$(gettext 'Installing kubelet for next kubernetes version ') $kubeVersion" >&2
    rpm -i --replacefiles --nodeps \
      $U7S_rpmDir/kubernetes${kubeMinorVersion}-kubelet_${kubeMinorVersion}.*.rpm 2>/dev/null
  fi
  kubeadmVersion=$(getCurrentKubeadmVersion)
  kubeadmMinorVersion=$(getMinorVersion $kubeadmVersion)
  if [ "$kubeMinorVersion" != "$kubeadmMinorVersion" ]
  then
    echo "$(gettext 'kubeadm minor version') $kubeadmMinorVersion "\
      "$(gettext 'does not match target minor version') $kubeMinorVersion" >&2
    exit 1
  fi

  if [ "$U7S_MasterNodeName" = "$U7S_HOSTNAME" ] #MASTER NODE
  then
    echo "$(gettext 'Get registry path in current cluster')" >&2
    clusterConfiguration=$(kubectl get -n kube-system configmaps kubeadm-config -o yaml | yq -r '.data.ClusterConfiguration')
    CURRENT_REGISTRYPATH=$(echo -ne "$clusterConfiguration" | yq -r .imageRepository)

    if [ "$CURRENT_REGISTRYPATH" != "$U7S_REGISTRYPATH" ]
    then
      echo "$(gettext 'Current platform does') $CURRENT_REGISTRYPATH $(gettext 'not match target') $U7S_REGISTRYPATH" >&2
      echo "$(gettext 'Update kubeadm-config to') $U7S_REGISTRYPATH" >&2
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
#   fi

  echo "$(gettext 'Loading kubernetes images for version') $kubeVersion" >&2
    machinectl shell u7s-admin@ \
    /usr/libexec/podsec/u7s/bin/nsenter_u7s \
      /usr/bin/kubeadm -v 9  config images pull \
        --image-repository=$U7S_REGISTRYPATH \
        --kubernetes-version=v${kubeVersion}
#   if [ "$U7S_MasterNodeName" = "$U7S_HOSTNAME" ] #MASTER NODE
#   then
    if [[ "$kubeMinorVersion" > '1.26' ]]
    then
      currentFlannelVersion=$(getCurrentFlannelVersion)
      toFlannelVersion='0.25.1'
      if [ "$currentFlannelVersion" != "$toFlannelVersion" ]
      then
        echo "$(gettext 'Upgrads flannel from') $currentFlannelVersion $(gettext 'to') $toFlannelVersion" >&2
        echo "$(gettext 'Remove rpm package cni-plugin-flannel-1.1.2')" >&2
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
          echo "$(gettext 'Waiting for service') kube-flannel:0.25.1 $(gettext 'to be restored')" >&2
          sleep 1
        done
      fi
    fi
#   fi


#   if [ "$U7S_MasterNodeName" = "$U7S_HOSTNAME" ] #MASTER NODE
#   then
    set -- $U7S_SlaveNodeNames
    nNodes=$#
    readyNodes=0
    while [ "$nNodes" -ne "$readyNodes" ]
    do
      readyNodes=0
      for slaveNode in $U7S_SlaveNodeNames
      do
        slaveKubeLetMinorVersion=$(getKubeletMinorVerion $slaveNode)
        deltaMinorVersions=$(getDeltaMinorVersions "$kubeMinorVersion" "$slaveKubeLetMinorVersion")
        if [ "$deltaMinorVersions" -le 1 ]
        then
          if [ "$deltaMinorVersions" -eq 1 ]
          then
            echo "$(gettext 'The deploying minor version') $kubeMinorVersion $(gettext 'of the master node') >&2 $U7S_MasterNodeName $(gettext 'is 1 higher, than the node') $slaveNode $(gettext 'version') $slaveKubeLetMinorVersion"
          elif [ "$deltaMinorVersions" -eq 0 ]
          then
            echo "$(gettext 'The deploying minor version') $kubeMinorVersion $(gettext 'of the master node') $U7S_MasterNodeName $(gettext 'IS EQUAL THE NODE') $slaveNode $(gettext 'version') $slaveKubeLetMinorVersion" >&2
          else
            echo "$(gettext 'THE DEPLOYING MINOR VERSION') $kubeMinorVersion $(gettext 'OF THE MASTER NODE') $U7S_MasterNodeName $(gettext 'IS MORE THAN 1 LOWER, THAN THE NODE') $slaveNode $(gettext 'VERSION') $slaveKubeProxyMinorVersion" >&2
            echo "$(gettext 'THERE MAY BE PROBLEMS UPGRATING THE CLUSTER.')" >&2
          fi
          let readyNodes+=1
        else
          if [ "$deltaMinorVersions" -gt 2 ]
          then
            echo "$(gettext 'THE DEPLOYING MINOR VERSION') $kubeMinorVersion $(gettext 'OF THE MASTER NODe') $U7S_MasterNodeName $(gettext 'IS MORE THAN 1 HIGHER, THAN THE NODE') $slaveNode $(gettext 'VERSION') $slaveKubeProxyMinorVersion" >&2
            echo "$(gettext 'THERE MAY BE PROBLEMS UPGRATING THE CLUSTER.')" >&2
          fi
          echo "$(gettext 'Waiting for the deployed minor version') $slaveKubeProxyMinorVersion $(gettext 'of the node') $slaveNode $(gettext 'to be updated to') $kubeMinorVersion" >&2
          sleep 10
          break
        fi
      done
    done
  else # WORKER OR ControlPlane Node
    masterKubeletMinorVersion=$(getKubeletMinorVerion $U7S_MasterNodeName)
    deltaMinorVersions=$(getDeltaMinorVersions "$kubeMinorVersion" "$masterKubeletMinorVersion")
    while [ "$deltaMinorVersions" -gt 0 ]
    do
      if [ "$deltaMinorVersions" -gt 1 ]
      then
        echo $(gettext 'THE DEPLOYING MINOR VERSION') $kubeMINORVERSION \
             $(gettext 'OF THE  NODE') $U7S_HOSTNAME \
             $(gettext 'IS MORE THAN 1 LOWER, THAN THE MASTER NODE') $U7S_MasterNodeName \
             $(gettext 'version') $masterKubeletMinorVersion >&2
        echo "$(gettext 'THERE MAY BE PROBLEMS UPGRATING THE CLUSTER.')" >&2
      fi
      echo "$(gettext 'Waiting for the deployed version') $masterKubeletMinorVersion $(gettext 'of the master node') $U7S_MasterNodeName $(gettext 'to be updated to') $kubeMinorVersion" >&2
      sleep 10
      masterKubeletMinorVersion=$(getKubeletMinorVerion $U7S_MasterNodeName)
      deltaMinorVersions=$(getDeltaMinorVersions "$kubeMinorVersion" "$masterKubeletMinorVersion")
    done
    if [ "$deltaMinorVersions" -lt -1 ]
    then
      echo "$(gettext 'THE DEPLOYING MINOR VERSION') $kubeMinorVersion $(gettext 'OF THE  NODE') $U7S_HOSTNAME $(gettext 'IS MORE THAN 1 LOWER, THAN THE MASTER NODE') $U7S_MasterNodeName $(gettext 'VERSION') $masterKubeletMinorVersion" >&2
      echo "$(gettext 'THERE MAY BE PROBLEMS UPGRATING THE CLUSTER.')" >&2
    fi
  fi

  cordonedNodes=$(listCordonedNodes)
  while [ -n "$cordonedNodes" ]
  do
    echo "$(gettext 'Waiting for uncordon nodes:') $cordonedNodes" >&2
    sleep 5
    cordonedNodes=$(listCordonedNodes)
  done

  echo -ne "$(gettext 'Cordon node') $HOSTNAME" >&2
  kubectl cordon $HOSTNAME

  echo "$(gettext 'Updating cluster node services to version') $kubeVersion" >&2
  echo "$(gettext 'Wait several minutes...')" >&2
  machinectl shell u7s-admin@ \
    /usr/libexec/podsec/u7s/bin/nsenter_u7s \
      /usr/bin/kubeadm upgrade apply -y ${kubeVersion} --ignore-preflight-errors=all

  if [[ "$kubeMinorVersion" > '1.29' ]]
  then
    echo -ne "$(gettext 'Remove node pods and containers')" >&2
    kubectl drain $HOSTNAME --ignore-daemonsets --delete-emptydir-data
    while killall kubelet 2>/dev/null; do sleep 1; done
    echo "$(gettext 'Remove all pods and containers')" >&2
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
  if [[ "$kubeMinorVersion" = '1.31' ]]
  then
    echo "$(gettext 'Installing kubelet for next kubernetes version ') $kubeVersion" >&2
    rpm -i --replacefiles --nodeps \
      $U7S_rpmDir/kubernetes${kubeMinorVersion}-kubelet_${kubeMinorVersion}.*.rpm 2>/dev/null
  fi

#   if [[ "$kubeMinorVersion" = '1.27' ]]
#   then
  listPrevRPMs=$(rpm -qa | grep 'cri-o
cri-tools
kubernetes' |
  grep "${prevKubeMinorVersion}")
  echo "$(gettext 'Removing rpm packeges') $listPrevRPMs $(gettext 'of previous kubernetes version ') ${prevKubeMinorVersion}" >&2
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
  echo "$(gettext 'Installing rpm packeges') $listNewRPMS $(gettext 'of new kubernetes version ') ${kubeMinorVersion}" >&2
  apt-get install -y $listNewRPMS

  echo -ne "$(gettext 'Restart node services')" >&2
  sleep 1
  systemctl start u7s
  machinectl shell u7s-admin@ /usr/bin/systemctl --user start kubelet

  echo -ne "$(gettext 'Waiting for kubelet node services to come up')." >&2
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
    echo -ne . >&2
    sleep 1
  done

  if [[ "$kubeMinorVersion" > '1.30' ]]
  then
    if [ $masterNodeName = $U7S_HOSTNAME ]
    then
      if kubectl get -n kube-system configmaps kubeadm-config -o yaml | grep ControlPlaneKubeletLocalModes >/dev/null
      then :;
      else
        kubectl get -n kube-system configmaps kubeadm-config -o yaml |
        yq -y '.' |
        sed -e 's/etcd:/etcd:\\n  featureGates:\\n    ControlPlaneKubeletLocalMode: true\n/' |
        kubectl apply -n kube-system  -f -
      fi
    fi
  fi

  kubectl uncordon $HOSTNAME
  if [ "$U7S_NodeRole" = 'controlplane' ]
  then
    echo $(gettext 'Untaint node') $HOSTNAME >&2
    kubectl taint nodes $HOSTNAME node-role.kubernetes.io/control-plane:NoSchedule-
  fi
#   if [ -z "$(getCurrentKubeAPIVersion)" ]
#   then
#     echo "$(gettext 'kubernetes services down')" >&2
#     echo "$(gettext 'Exit')" >&2
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



