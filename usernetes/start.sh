#!/bin/sh

/docker-entrypoint.sh unsudo /home/user/usernetes/boot/docker-2ndboot.sh --cri=crio --cni=flannel
