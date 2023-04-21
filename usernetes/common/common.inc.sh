#!/bin/sh
# Common functions

# Customizable environment variables:
# * $U7S_BASE_DIR: Usernetes base directory
# * $U7S_DEBUG: enable debug mode if set to "1"

# Environment variables set by this script:
# * $PATH: $U7S_BASE_DIR/bin:/sbin:/usr/sbin are prepended
# * $XDG_DATA_HOME: $HOME/.local/share if not set
# * $XDG_CONFIG_HOME: $HOME/.config if not set
# * $XDG_CACHE_HOME: $HOME/.cache if not set

set -euo pipefail

# logging utilities
debug_enabled() {
	: ${U7S_DEBUG=0}
	[[ $U7S_DEBUG == 1 ]] || [[ $U7S_DEBUG == true ]]
}

log_debug() {
	if debug_enabled; then
		echo -e "\e[102m\e[97m[DEBUG]\e[49m\e[39m $@"
	fi
}

log_info() {
	echo -e "\e[104m\e[97m[INFO]\e[49m\e[39m $@"
}

log_info_n() {
	echo -n -e "\e[104m\e[97m[INFO]\e[49m\e[39m $@"
}

log_warning() {
	echo -e "\e[101m\e[97m[WARN]\e[49m\e[39m $@"
}

log_error() {
	echo -e "\e[101m\e[97m[ERROR]\e[49m\e[39m $@"
}

# nsenter utilities
nsenter_main() {
	: ${_U7S_NSENTER_CHILD=0}
	if [[ $_U7S_NSENTER_CHILD == 0 ]]; then
		_U7S_NSENTER_CHILD=1
		export _U7S_NSENTER_CHILD
		nsenter__nsenter_retry_loop
		rc=0
		nsenter__nsenter $@ || rc=$?
		exit $rc
	fi
}

nsenter__nsenter_retry_loop() {
	local max_trial=10
	log_info_n "Entering RootlessKit namespaces: "
	for ((i = 0; i < max_trial; i++)); do
		rc=0
		nsenter__nsenter echo OK 2>/dev/null || rc=$?
		if [[ rc -eq 0 ]]; then
			return 0
		fi
		echo -n .
		sleep 1
	done
	log_error "nsenter failed after ${max_trial} attempts, RootlessKit not running?"
	return 1
}

nsenter__nsenter() {
	local pidfile=$XDG_RUNTIME_DIR/usernetes/rootlesskit/child_pid
	if ! [[ -f $pidfile ]]; then
		return 1
	fi
	# workaround for https://github.com/rootless-containers/rootlesskit/issues/37
	# see the corresponding code in boot/rootlesskit.sh
	local pidreadyfile=$XDG_RUNTIME_DIR/usernetes/rootlesskit/_child_pid.u7s-ready
	if ! [[ -f $pidreadyfile ]]; then
		return 1
	fi
	if ! [[ $(cat $pidfile) -eq $(cat $pidreadyfile) ]]; then
		return 1
	fi
	export ROOTLESSKIT_STATE_DIR=$XDG_RUNTIME_DIR/usernetes/rootlesskit
	# TODO(AkihiroSuda): ping to $XDG_RUNTIME_DIR/usernetes/rootlesskit/api.sock
	nsenter --user --preserve-credential --mount --net --cgroup --pid --ipc --uts -t $(cat $pidfile) --wd=$PWD -- $@
}

setEnvsByYaml() {
	yamlFile=$1
	ifs=$IFS
	for assign in $(yq '.spec.containers[0].command' $yamlFile | grep -- '"--')
	do
	  if [ "${assign:0-1}" = ',' ]
	  then
			assign=${assign:3:-2}
		else
			assign=${assign:3:-1}
		fi
		IFS==
		set -- $assign
		IFS=$ifs
		var=$1
		value=$2
		IFS=-
		set -- $var
		IFS=$ifs
		varsh=$1
		shift
		for p
		do
		  varsh+="_$p"
		done
		echo "export $varsh=$value"
	done
}


# entrypoint begins
if debug_enabled; then
	log_warning "Running in debug mode (\$U7S_DEBUG)"
fi

# verify necessary environment variables
if ! [[ -w $XDG_RUNTIME_DIR ]]; then
	log_error "XDG_RUNTIME_DIR needs to be set and writable"
	return 1
fi
if ! [[ -w $HOME ]]; then
	log_error "HOME needs to be set and writable"
	return 1
fi

: ${U7S_BASE_DIR=}
if [[ -z $U7S_BASE_DIR ]]; then
	log_error "Usernetes base directory (\$U7S_BASE_DIR) not set"
	return 1
fi
log_debug "Usernetes base directory (\$U7S_BASE_DIR) = $U7S_BASE_DIR"
if ! [[ -d $U7S_BASE_DIR ]]; then
	log_error "Usernetes base directory ($U7S_BASE_DIR) not found"
	return 1
fi

# export PATH
PATH=$U7S_BASE_DIR/bin:/sbin:/usr/sbin:$PATH
export PATH

# export XDG_{DATA,CONFIG,CACHE}_HOME
: ${XDG_DATA_HOME=$HOME/.local/share}
: ${XDG_CONFIG_HOME=$HOME/.config}
: ${XDG_CACHE_HOME=$HOME/.cache}
export XDG_DATA_HOME XDG_CONFIG_HOME XDG_CACHE_HOME



