#!/bin/sh
# Customizable environment variables:
# * $U7S_ROOTLESSKIT_FLAGS
# set -x
source podsec-u7s-functions

source $envFile

rk_state_dir=$XDG_RUNTIME_DIR/usernetes/rootlesskit

: ${U7S_ROOTLESSKIT_FLAGS=}

: ${_U7S_CHILD=0}
if [[ $_U7S_CHILD == 0 ]]; then
	_U7S_CHILD=1
	if hostname -I &>/dev/null ; then
		: ${U7S_PARENT_IP=$(hostname -I | sed -e 's/ .*//g')}
	else
		: ${U7S_PARENT_IP=$(hostname -i | sed -e 's/ .*//g')}
	fi
	export _U7S_CHILD U7S_PARENT_IP

	# To route ping packets - see https://github.com/rootless-containers/usernetes
# 	echo "0 2147483647"  > /proc/sys/net/ipv4/ping_group_range

	# Re-exec the script via RootlessKit, so as to create unprivileged {user,mount,network} namespaces.
	#
	# --net specifies the network stack. slirp4netns and VPNKit are supported.
	# Currently, slirp4netns is the fastest.
	# See https://github.com/rootless-containers/rootlesskit for the benchmark result.
	#
	# --copy-up allows removing/creating files in the directories by creating tmpfs and symlinks
	# * /etc: copy-up is required so as to prevent `/etc/resolv.conf` in the
	#         namespace from being unexpectedly unmounted when `/etc/resolv.conf` is recreated on the host
	#         (by either systemd-networkd or NetworkManager)
	# * /run: copy-up is required so that we can create /run/* in our namespace
	# * /var/lib: copy-up is required for several Kube stuff
	# * /opt: copy-up is required for mounting /opt/cni/bin
	rootlesskit \
		--state-dir $rk_state_dir \
		--net=slirp4netns --mtu=65520 --disable-host-loopback --slirp4netns-sandbox=true --slirp4netns-seccomp=true \
		--port-driver=builtin \
		--copy-up=/etc --copy-up=/etc/sysconfig/ --copy-up=/run --copy-up=/var/lib --copy-up=/opt \
		--copy-up=/var/lib/crio \
		-copy-up=/usr/libexec/ \
		--cgroupns \
		--pidns \
		--ipcns \
		--utsns \
		--propagation=rslave \
		--evacuate-cgroup2="rootlesskit_evac" \
		$U7S_ROOTLESSKIT_FLAGS \
		$0 $@
else
	# save IP address
	echo $U7S_PARENT_IP >$XDG_RUNTIME_DIR/usernetes/parent_ip

	# Remove symlinks so that the child won't be confused by the parent configuration
	rm -f \
		/run/xtables.lock /run/netns \
		/run/runc /run/crun  /run/flannel \
		/run/containerd /run/containers /run/crio \
		/etc/cni \
		/etc/containerd /etc/crio

	mkdir -p /etc/kubernetes/pki
	mkdir -p /usr/libexec/kubernetes

	# Copy CNI config to /etc/cni/net.d (Likely to be hardcoded in CNI installers)
	mkdir -p /etc/cni/net.d
	cp -f /etc/podsec/u7s/config/cni_net.d/* /etc/cni/net.d
	cp -f /etc/podsec/u7s/config/flannel/cni_net.d/* /etc/cni/net.d
	mkdir -p /run/flannel
	# Bind-mount /opt/cni/net.d (Likely to be hardcoded in CNI installers)
	mkdir -p /opt/cni/bin
	mount --bind /usr/libexec/cni /opt/cni/bin

	mkdir -p /run/crio/
	ln -sf /run/user/$U7S_UID/usernetes/crio/crio.sock /run/crio/crio.sock

	# These bind-mounts are needed at the moment because the paths are hard-coded in Kube and CRI-O.
	binds=(/var/lib/kubelet /var/lib/cni /var/log /var/lib/containers /var/cache)
	for f in ${binds[@]}; do
		src=$XDG_DATA_HOME/usernetes/$(echo $f | sed -e s@/@_@g)
		if [[ -L $f ]]; then
			# Remove link created by `rootlesskit --copy-up` if any
			rm -rf $f
		fi
		mkdir -p $src $f
		mount --bind $src $f
	done

	rk_pid=$(cat $rk_state_dir/child_pid)
	# workaround for https://github.com/rootless-containers/rootlesskit/issues/37
	# child_pid might be created before the child is ready
	echo $rk_pid >$rk_state_dir/_child_pid.u7s-ready
	log_info "RootlessKit ready, PID=${rk_pid}, state directory=$rk_state_dir ."
	log_info "Hint: You can enter RootlessKit namespaces by running \`nsenter -U --preserve-credential -n -m -t ${rk_pid}\`."
	if [ -n "$U7S_CONTROLPLANE" ]
	then
		ports="2379 2380 6443 10250 10255 10256"
	else
		ports="10250 10255 10256"
	fi
	for port in $ports
	do
		rootlessctl --socket $rk_state_dir/api.sock add-ports "0.0.0.0:${port}:${port}/tcp"
	done
# 	rootlessctl --socket $rk_state_dir/api.sock add-ports 0.0.0.0:30080:30080/tcp
	rootlessctl --socket $rk_state_dir/api.sock add-ports 0.0.0.0:8472:8472/udp
	rootlessctl --socket $rk_state_dir/api.sock add-ports 0.0.0.0:6053:53/udp

	# Обеспечить выделение статичесикх IP-адресов для tap0 интерфейсов и роутнг пакетов до них
	until /sbin/ip a add ${U7S_TAPIP}/32 dev tap0; do sleep 1; done
	/sbin/ip a del $U7S_SLIRP4IP/$U7S_SERVICEMASK dev tap0;
	if [ -n "$U7S_CONTROLPLANE" ]
	then
		/sbin/iptables -A PREROUTING -t nat -p tcp --dport 443 -j DNAT --to ${U7S_TAPIP}:6443
	fi

	rc=0
	if [[ $# -eq 0 ]]; then
		sleep infinity || rc=$?
	else
		$@ || rc=$?
	fi
	log_info "RootlessKit exiting (status=$rc)"
	exit $rc
fi
