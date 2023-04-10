#!/bin/bash
set -eu -o pipefail
source $(realpath $(dirname $0))/smoketest-common.inc.sh
if [[ $# -lt 3 ]]; then
	echo "Usage: $0 NAME IMAGE ARGS"
	exit 1
fi

cd $(realpath $(dirname $0)/..)
container=$1
image=$2
shift 2
args=$@

# set -x
tmpdir=$(mktemp -d)
docker run -td --name $container  -v /lib/modules:/lib/modules -p 127.0.0.1:6443:6443 --privileged $image $args
function cleanup() {
	docker rm -f $container
	rm -rf $tmpdir
}
trap cleanup EXIT

if ! timeout 60 sh -exc "until [ \$(docker inspect -f '{{.State.Health.Status}}' $container) = \"healthy\" ]; do sleep 10; done"; then
	docker logs $container
	exit 1
fi

docker cp $container:/home/user/.config/usernetes/master/admin-localhost.kubeconfig $tmpdir/admin-localhost.kubeconfig
export KUBECONFIG=$tmpdir/admin-localhost.kubeconfig

mkdir -p $tmpdir/bin
docker cp $container:/usr/bin/kubectl $tmpdir/bin/kubectl
chmod +x $tmpdir/bin/kubectl
export PATH=$tmpdir/bin:$PATH

kubectl get nodes -o wide
: "FIXME remove this sleep"
sleep 30
if ! timeout 60 time kubectl run --rm -i --image busybox --restart=Never hello echo hello $container; then
	kubectl get pods -o yaml
	kubectl get nodes -o yaml
	docker logs $container
	exit 1
fi

smoketest_dns
