#!/bin/sh

docker rm -f alt-usernetes-node
docker run -td -v /lib/modules:/lib/modules --name alt-usernetes-node -p 127.0.0.1:6443:6443 --privileged rootless-containers/usernetes --cri=crio --cni=flannel

# docker run -it --name alt-usernetes-node -p 127.0.0.1:8443:6443 --privileged --entrypoint=/bin/bash rootless-containers/usernetes #--cri=containerd
