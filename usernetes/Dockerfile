FROM registry.altlinux.org/alt/alt:p10
# ARG User=user


RUN \
  apt-get update ;\
  ListSystem='systemd-container shadow-submap conntrack-tools \
    findutils fuse3 iproute iptables procps-ng time which less \
    vim-console su net-tools openssh passwd'; \
  ListKuber=' \
  podman \
  skopeo \
  kubernetes-client \
  kubernetes-common \
  kubernetes-crio \
  kubernetes-kubeadm \
  kubernetes-kubelet \
  kubernetes-master \
  kubernetes-node \
  kubernetes-pause \
  etcd \
  flannel \
  cni-plugin-flannel \
  fuse-overlayfs \
  rootlesskit \
  slirp4netns \
  crun \
  cri-tools \
  '; \
  apt-get install -y $ListSystem $ListKuber; \
  systemctl  enable --now sshd; \
  mkdir -p /etc/systemd/system/user@.service.d/; \
  echo -ne    "tun\n\
tap\n\
bridge\n\
br_netfilter\n\
veth\n\
ip6_tables\n\
iptable_nat\n\
ip6table_nat\n\
iptable_filter\n\
ip6table_filter\n\
nf_tables\n\
xt_MASQUERADE\n\
xt_addrtype\n\
xt_comment\n\
xt_conntrack\n\
xt_mark\n\
xt_multiport\n\
xt_nat\n\
xt_tcpudp\n\
" > /etc/modules-load.d/u7s.conf


ADD docker-entrypoint.sh /docker-entrypoint.sh
COPY hack/etc_systemd_system_user@.service.d_delegate.conf /etc/systemd/system/user@.service.d/delegate.conf

# SET new version flanneld
COPY flannel_0.19.tgz /tmp
RUN  cd /;tar xvzf /tmp/flannel_0.19.tgz

RUN chmod +x /docker-entrypoint.sh && \
  groupadd -r podman; \
# As of Feb 2020, Fedora has wrong permission bits on newuidmap and newgidmap.
  chmod 4755 /usr/bin/newuidmap /usr/bin/newgidmap && \
  chmod +s /usr/bin/newuidmap /usr/bin/newgidmap && \
  groupadd --system u7s-admin && \
  useradd --create-home --system --home-dir /home/u7s-admin -g u7s-admin -G systemd-journal,podman,fuse u7s-admin && \
  mkdir -p /home/u7s-admin/.local /home/u7s-admin/.config/usernetes && \
  chown -R u7s-admin:u7s-admin /home/u7s-admin

RUN \
  mkdir /usr/libexec/kubernetes; \
  chmod 777 /usr/libexec/kubernetes

COPY --chown=u7s-admin:u7s-admin . /home/u7s-admin/usernetes
RUN ln -sf /home/u7s-admin/usernetes/boot/docker-unsudo.sh /usr/local/bin/unsudo

#
RUN \
  cd /home/u7s-admin/usernetes; tar xvzf cfssl.tgz

RUN mkdir -p /var/lib/crio/; chmod 777 /var/lib/crio/

# COPY start.sh /

# RUN set -x;  \
#   ls -l /dev/pts/ptmx; \
#   chmod 666 /dev/pts/ptmx; \
#   ls -Ll /dev/ptmx


VOLUME /home/u7s-admin/.local
VOLUME /home/u7s-admin/.config
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
  CMD ["unsudo", "systemctl", "--user", "is-system-running"]
ENTRYPOINT ["/docker-entrypoint.sh", "unsudo", "/home/u7s-admin/usernetes/boot/docker-2ndboot.sh"]

