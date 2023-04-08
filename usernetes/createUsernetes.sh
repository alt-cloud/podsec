#!/bin/sh
sh -c 'apt-get update ;  ListSystem='"'"'systemd-container shadow-submap conntrack-tools     findutils fuse3 iproute iptables procps-ng time which less     vim-console su net-tools  passwd'"'"';   ListKuber='"'"'   podman   skopeo   kubernetes-client   kubernetes-common   kubernetes-crio   kubernetes-kubeadm   kubernetes-kubelet   kubernetes-master   kubernetes-node   kubernetes-pause   etcd   flannel   cni-plugin-flannel   fuse-overlayfs   rootlesskit   slirp4netns   crun   cri-tools   '"'"';   apt-get install -y $ListSystem $ListKuber;   systemctl  enable --now sshd;   mkdir -p /etc/systemd/system/user@.service.d/;   echo -ne    "tun\ntap\nbridge\nbr_netfilter\nveth\nip6_tables\niptable_nat\nip6table_nat\niptable_filter\nip6table_filter\nnf_tables\nxt_MASQUERADE\nxt_addrtype\nxt_comment\nxt_conntrack\nxt_mark\nxt_multiport\nxt_nat\nxt_tcpudp\n" > /etc/modules-load.d/u7s.conf'
cp  docker-entrypoint.sh /docker-entrypoint.sh
cp  hack/etc_systemd_system_user@.service.d_delegate.conf /etc/systemd/system/user@.service.d/delegate.conf
cp  flannel_0.19.tgz /tmp
sh -c 'cd /;tar xvzf /tmp/flannel_0.19.tgz'
sh -c 'chmod +x /docker-entrypoint.sh &&   groupadd -r podman;   chmod 4755 /usr/bin/newuidmap /usr/bin/newgidmap &&   chmod +s /usr/bin/newuidmap /usr/bin/newgidmap &&   groupadd --system u7s-admin &&   useradd --create-home --system --home-dir /home/u7s-admin -g u7s-admin -G systemd-journal,podman,fuse u7s-admin &&   mkdir -p /home/u7s-admin/.local /home/u7s-admin/.config/usernetes &&   chown -R u7s-admin:u7s-admin /home/u7s-admin'
sh -c 'mkdir /usr/libexec/kubernetes;   chmod 777 /usr/libexec/kubernetes'
cp -R  . /home/u7s-admin/usernetes
chown -R u7s-admin:u7s-admin /home/u7s-admin/usernetes
sh -c 'ln -sf /home/u7s-admin/usernetes/boot/docker-unsudo.sh /usr/local/bin/unsudo'
sh -c 'mkdir -p /home/u7s-admin/usernetes/bin;   mv /home/u7s-admin/usernetes/cfssl /home/u7s-admin/usernetes/cfssljson /home/u7s-admin/usernetes/bin;'
sh -c 'mkdir -p /var/lib/crio/; chmod 777 /var/lib/crio/'

modprobe -a $(cat /etc/modules-load.d/k7s.conf)

env >/etc/docker-entrypoint-env

cat >/etc/systemd/system/docker-entrypoint.target <<EOF
[Unit]
Description=the target for docker-entrypoint.service
Requires=docker-entrypoint.service systemd-logind.service systemd-user-sessions.service
EOF

quoted_args="$(printf " %q" "${@}")"
echo "${quoted_args}" >/etc/docker-entrypoint-cmd

cat >/etc/systemd/system/docker-entrypoint.service <<EOF
[Unit]
Description=docker-entrypoint.service

[Service]
ExecStart=/bin/bash -exc "source /etc/docker-entrypoint-cmd"
# EXIT_STATUS is either an exit code integer or a signal name string, see systemd.exec(5)
ExecStopPost=/bin/bash -ec "if echo \${EXIT_STATUS} | grep [A-Z] > /dev/null; then echo >&2 \"got signal \${EXIT_STATUS}\"; systemctl exit \$(( 128 + \$( kill -l \${EXIT_STATUS} ) )); else systemctl exit \${EXIT_STATUS}; fi"
StandardInput=tty-force
StandardOutput=inherit
StandardError=inherit
WorkingDirectory=$(pwd)
EnvironmentFile=/etc/docker-entrypoint-env

[Install]
WantedBy=multi-user.target
EOF

systemctl mask systemd-firstboot.service systemd-udevd.service
# systemctl unmask systemd-logind
systemctl enable docker-entrypoint.service
