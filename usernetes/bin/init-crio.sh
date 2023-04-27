#!/bin/sh

uid=$(id -u u7s-admin)
mkdir -p /run/user/$uid/usernetes/crio/
mksock /run/user/$uid/usernetes/crio/crio.sock 2>/dev/null
chmod 660 /run/user/$uid/usernetes/crio/crio.sock
# mkdir -p /run/containerd /run/flannel
# ln -sf /run/user/$uid/usernetes/crio/crio.sock /run/containerd/containerd.sock
# /bin/chown -R  u7s-admin:u7s-admin /run/user/$uid /run/flannel/
