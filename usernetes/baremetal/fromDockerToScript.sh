#!/bin/sh
exec > ../usernetes/createUsernetes.sh

./dockerfileToShell.py

cat fromDockerToScript.template
