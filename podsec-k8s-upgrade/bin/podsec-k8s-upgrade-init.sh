3#!/bin/sh
# ISO= https://cloud.ivk.ru/seafhttp/files/0f15f133-8eb7-419e-9d08-74850a7e1686/1.26_c10f1-1.31_c10f2.iso

source ./podsec-k8s-upgrade-functions

export TEXTDOMAINDIR='/usr/share/locale'
export TEXTDOMAIN='podsec-k8s-upgrade'

function format() {
  echo "$(gettext 'Format'):"
  echo -ne "  $0 [--rpms URLOfRpmArcjive] [--oci URLOfOCI-archive] [--manifests URLOfFlannelManifests] [--iso URLOfISO]"
}

# MAIN
sed -i s/c10f1/c10f2/ /etc/os-release
getPlatform
if [ ${U7S_PLATFORM:0:-1} = 'c10f' ]
then
  U7S_PLATFORM=${U7S_PLATFORM:0:-1}
fi

vars=''
if [ $# -gt 0 ]
then
  if vars=$(getopt -n $0 -o r:,o:,m:,i: --long rpms:,oci:,manifests:,iso: -- "$@")
  then :;
  else
    format >&2
    exit $?
  fi
fi

eval set -- "$vars"
RPMS= OCI= MANIFESTS= ISO=
for opt
do
  case "$opt" in
    -r|--rpms)
      RPMS=$2
      shift 2
      ;;
    -o|--oci)
      OCI=$2
      shift 2
      ;;
    -m|--manifests)
      MANIFESTS=$2
      shift 2
      ;;
    -i|--iso)
      ISO=$2;
      shift 2
  esac
done

echo "RPMS=$RPMS OCI=$OCI MANIFESTS=$MANIFESTS ISO=$ISO"

echo ""
shift
if [ "$#" != 0 ]
then
  echo "$(gettext 'Incorrect format') $ip" >&2
  format >&2
  exit 1
fi

# if [ -n "$ISO" ]
# then
#   if [ -n "$RPMS" -o -n "$OCI" -o -n "$MANIFESTS" ]
#   then
#     echo "$(gettext 'The --iso(-i) flag and the --rpms(-r), --oci(-o) and --MANIFESTS(-m) flags are mutually exclusive') $ip" >&2
#     format >&2
#     exit 1
#   fi
# fi

if [ -n "$ISO" ]
then
  isoPlacemant=/root/tmp
  ISOMountDir='/run/mount/ISO-podsec-k8s-upgrade'
  rest=${ISO#*://}
  if [ $rest != $ISO ] # $ISO contains ://
  then
    let l=${#ISO}-${#rest}-3
    protocol=${ISO:0:$l}
    mkdir -p $isoPlacemant
    isofile=$(basename $rest)
    ISOFILE="$isoPlacemant/$isofile"
    if ! curl -C - $ISO --output $ISOFILE
    then
      echo "$gettext 'Cannot load URL $ISO'" >&2
      exit 1
    fi
  else # $ISO - file in local filesystem
    ISOFILE=$ISO
  fi
  if [ $(file -bL --mime-type $ISOFILE) != 'application/x-iso9660-image' ]
  then
    echo "$(gettext 'file $ISOFILE is not ISO')" >&2
    exit 2
  fi
  mkdir -p $ISOMountDir
  umount -q $ISOMountDir
  mount -r $ISOFILE $ISOMountDir
  if [ -z "$OCI" ]
  then
    OCI=$(find $ISOMountDir -name amd64_*_tar.xz)
  fi
  if [ -z "$RPMS" ]
  then
    rpmsmain=$(find $ISOMountDir -name RPMS.main)
    RPMS=$(realpath "$rpmsmain/..")
  fi
  if [ -z "$MANIFESTS" ]
  then
    kubeflannel=$(find $ISOMountDir -name kube-flannel)
    MANIFESTS=$(realpath "$kubeflannel/..")
  fi
fi

LOCALREGISTRY='registry.local'
if [ -n "$OCI" ]
then
  if curl -q  http://registry.local/v2/_catalog 2>/dev/null # Дистрибутив c10 с поддержкой registry.local
  then
    REGISTRY=$LOCALREGISTRY
  else
    REGISTRY='registry.altlinux.org'
  fi
  if [ ${U7S_PLATFORM} = 'k8s-c10f' ]
  then
    if [ "$REGISTRY" != $LOCALREGISTRY ]
    then
      echo "${U7S_PLATFORM} $(gettext 'platform distribution must use the') $LOCALREGISTRY $(gettext 'docker registry. It is not available')" >&2
      exit 1
    fi
  else
    if [ "$REGISTRY" != $LOCALREGISTRY ]
    then
      echo "${U7S_PLATFORM} $(gettext 'platform distribution does not usually use the') $LOCALREGISTRY $(gettext 'docker registry') $LOCALREGISTRY" >&2
    fi
  fi
fi

if [ "$REGISTRY" = $LOCALREGISTRY ]
then
  podmanDevUser=$(getPGPMemberOfPodsecDev)
  if [ -z "$podmanDevUser" ]
  then
    echo $(gettext 'There is no user in the system that belongs to the podman_dev group and has a GPG-key') >&2
    exit 1
  fi
  echo $(gettext 'Found user') $podmanDevUser $(gettext 'belonging to group podman_dev and having GPG-key') >&2
  echo $(gettext 'Extracting images from the archive and placing them in registry.local') >&2
  GPGUID=$(machinectl shell ${podmanDevUser}@ /usr/bin/gpg2 -k | head -4 | tail -1 | tr -d " \n\r")
  machinectl shell ${podmanDevUser}@ /usr/bin/podsec-load-sign-oci $OCI amd64 "$GPGUID"
fi
