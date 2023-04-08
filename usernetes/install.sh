#!/bin/bash
set -e -o pipefail

. ./podsec-u7s-functions

set -x
### Detect BASE dir
cd $(dirname $0)
# BASE=$(realpath $(pwd))
# BASE=/home/u7s-admin/usernetes

### Detect bin dir, fail early if not found
if [ ! -d "$BASE/bin" ]; then
	ERROR "Usernetes binaries not found. Run \`make\` to build binaries. If you are looking for binary distribution of Usernetes, see https://github.com/rootless-containers/usernetes/releases ."
	exit 1
fi

### Detect config dir
set +u
if [ -z "$HOMEDIR" ]; then
	ERROR "HOME needs to be set"
	exit 1
fi
if [ -n "$XDG_CONFIG_HOME" ]; then
	CONFIG_DIR="$XDG_CONFIG_HOME"
fi
set -u

### Parse args
arg0=$0

delay=""
WAIT_INIT_CERTS=""
function usage() {
	echo "Usage: ${arg0} [OPTION]..."
	echo "Install Usernetes systemd units to ${CONFIG_DIR}/systemd/unit ."
	echo
	echo "  --start=UNIT        Enable and start the specified target after the installation, e.g. \"u7s.target\". Set to an empty to disable autostart. (Default: \"$StartTarget\")"
	echo "  --CRI=RUNTIME       Specify CRI runtime, \"containerd\" or \"crio\". (Default: \"$CRI\")"
	echo '  --cni=RUNTIME       Specify CNI, an empty string (none) or "flannel". (Default: none)'
	echo "  -p, --publish=PORT  Publish ports in RootlessKit's network namespace, e.g. \"0.0.0.0:10250:10250/tcp\". Can be specified multiple times. (Default: \"${publish_default}\")"
	echo "  --cidr=CIDR         Specify CIDR of RootlessKit's network namespace, e.g. \"10.0.100.0/24\". (Default: \"$CIDR\")"
	echo
	echo "Examples:"
	echo "  # The default options"
	echo "  ${arg0}"
	echo
	echo 'Use `uninstall.sh` for uninstallation.'
	echo 'For an example of multi-node cluster with flannel, see docker-compose.yaml'
	echo
	echo 'Hint: `sudo loginctl enable-linger` to start user services automatically on the system start up.'
}

set +e
args=$(getopt -o hp: --long help,publish:,start:,cri:,cni:,cidr:,,delay:,wait-init-certs -n $arg0 -- "$@")
getopt_status=$?
set -e
if [ $getopt_status != 0 ]; then
	usage
	exit $getopt_status
fi
eval set -- "$args"
while true; do
	case "$1" in
	-h | --help)
		usage
		exit 0
		shift
		;;
	-p | --publish)
		PUBLISH="$PUBLISH $2"
		shift 2
		;;
	--start)
		StartTarget="$2"
		shift 2
		;;
	--cni)
		cni="$2"
		case "$CNI" in
		"" | "flannel") ;;

		*)
			ERROR "Unknown CNI \"$CNI\". Supported values: \"\" (default) \"flannel\" ."
			exit 1
			;;
		esac
		shift 2
		;;
	--cidr)
		CIDR="$2"
		shift 2
		;;
	--delay)
		# HIDDEN FLAG. DO NO SPECIFY MANUALLY.
		delay="$2"
		shift 2
		;;
	--wait-init-certs)
		# HIDDEN FLAG FOR DOCKER COMPOSE. DO NO SPECIFY MANUALLY.
		WAIT_INIT_CERTS=1
		shift 1
		;;
	--)
		shift
		break
		;;
	*)
		break
		;;
	esac
done

# set default --publish if none was specified
if [[ -z "$PUBLISH" ]]; then
	PUBLISH=$PUBLISH_DEFAULT
fi

checkSystemEnv

# check cgroup config

f="/sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.controllers"
if [[ ! -f $f ]]; then
	ERROR "systemd not running? file not found: $f"
	exit 1
fi
if ! grep -q cpu $f; then
	WARNING "cpu controller might not be enabled, you need to configure /etc/systemd/system/user@.service.d , see https://rootlesscontaine.rs/getting-started/common/cgroup2/"
elif ! grep -q memory $f; then
	WARNING "memory controller might not be enabled, you need to configure /etc/systemd/system/user@.service.d , see https://rootlesscontaine.rs/getting-started/common/cgroup2/"
else
	INFO "Rootless cgroup (v2) is supported"
fi


# Delay for debugging
if [[ -n "$delay" ]]; then
	INFO "Delay: $delay seconds..."
	sleep "$delay"
fi

createU7Environments

### Finish installation
systemctl --user daemon-reload
if [ -z $StartTarget ]; then
	INFO 'Run `systemctl --user -T start u7s.target` to start Usernetes.'
	exit 0
fi
INFO "Starting $StartTarget"
# set -x
systemctl --user -T enable $StartTarget
time systemctl --user -T start $StartTarget
systemctl --user --all --no-pager list-units 'u7s-*'
# set +x

KUBECONFIG=
if systemctl --user -q is-active u7s-master.target; then
	PATH="${BASE}/bin:$PATH"
	KUBECONFIG="${CONFIG_DIR}/usernetes/master/admin-localhost.kubeconfig"
	export PATH KUBECONFIG
	INFO "Installing CoreDNS"
	# sleep for waiting the node to be available
	sleep 3
	kubectl get nodes -o wide
	kubectl apply -f ${BASE}/manifests/coredns.yaml
	INFO "Waiting for CoreDNS pods to be available"
	# sleep for waiting the pod object to be created
	sleep 3
	kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=kube-dns
	kubectl get pods -A -o wide
fi

INFO "Installation complete."
INFO 'Hint: `sudo loginctl enable-linger` to start user services automatically on the system start up.'
if [[ -n "${KUBECONFIG}" ]]; then
	INFO "Hint: export KUBECONFIG=${KUBECONFIG}"
fi
