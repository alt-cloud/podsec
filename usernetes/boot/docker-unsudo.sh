#!/bin/sh
set -eux
car=$1
shift
cdr=$@
# machinectl requires absolute path
exec machinectl shell u7s-admin@ $(which $car) $cdr
