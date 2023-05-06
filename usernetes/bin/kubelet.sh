#!/bin/sh
source u7s_finctions

set -x
nsenter_u7s _kubelet.sh $@


