#!/bin/sh
# set -x
uid=$(id -u u7s-admin)
mkdir -p /run/user/$uid/usernetes/crio/
mksock /run/user/$uid/usernetes/crio/crio.sock 2>/dev/null
chmod 660 /run/user/$uid/usernetes/crio/crio.sock

