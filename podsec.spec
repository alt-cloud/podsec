%define u7s_admin_usr u7s-admin
%define u7s_admin_usr_temp u7sadmin
%define u7s_admin_grp u7s-admin

Name: podsec
Version: 0.5.1
Release: alt1

Summary: Set of scripts for Podman Security
License: GPLv2+
Group: Development/Other
Url: https://github.com/alt-cloud/podsec
BuildArch: noarch

Source: %name-%version.tar

Requires: podman >= 4.4.2
Requires: shadow-submap >= 4.5
Requires: nginx >= 1.22.1
Requires: docker-registry >= 2.8.1
Requires: pinentry-common >= 1.1.0
Requires: jq >= 1.6
Requires: yq >= 2.12.2
Requires: fuse-overlayfs >= 1.1.2.3.800011b
Requires: skopeo >= 1.9.1
Requires: sh >= 4.4.23
Requires: wget >= 1.21.3
Requires: coreutils >= 8.32.0
Requires: conntrack-tools >= 1.4.6
Requires: findutils >= 4.8.0
Requires: fuse3 >= 3.10.2
Requires: iproute2 >= 5.13.0
Requires: iptables >= 1.8.7
Requires: openssh-server >= 7.8

%description
This package contains utilities for:
- setting the most secure container application access policies
  (directory /etc/containers/)
- installation of a registry and a web server for access to image signatures
- creating a user with rights to create docker images, signing them and
  placing them in the registry
- creating users with rights to run containers in rootless mode
- downloading docker images from the oci archive, placing them
  on the local system, signing and placing them on the registry

%package k8s
Summary: Set of scripts for Kubernetes Security
Group: Development/Other
Requires: podsec >= 0.3.1
Requires: kubernetes-kubeadm >= :1.26.3
Requires: kubernetes-kubelet >= :1.26.3
Requires: kubernetes-crio >= :1.26.3
Requires: kubernetes-master >= 1.26.3
Requires: kubernetes-node >= 1.26.3
Requires: etcd >= 3.4.15
Requires: flannel >= 0.13.0
# Requires: flannel >= 0.19.2
Requires: cni-plugin-flannel >= 1.2.0
Requires: rootlesskit >= 1.1.0
Requires: slirp4netns >= 1.1.12
Requires: crun >= 1.8.1
Requires: cri-o >= 1.26.2
Requires: cri-tools >= 1.22.0
Requires: kubernetes-client >= :1.26.3
Requires: systemd-container >= 249.16
%filter_from_requires /\/etc\/kubernetes\/kubelet/d
# %filter_from_requires /\/usr\/bin\/chown/d

%description k8s
This package contains utilities for:
- cluster node configurations


%package k8s-rbac
Summary: Set of scripts for Kubernetes RBAC
Group: Development/Other
Requires: kubernetes-client >= :1.26.3
Requires: podsec >= 0.3.1
Requires: curl >= 7.88.0


%description k8s-rbac
This package contains utilities for
- creating RBAC users
- generation of certificates and configuration files for users
- generating cluster and usual roles and binding them to users

%package nagios-plugins
Summary: Set of scripts for nagios monitoring
Group: Development/Other
Requires: nagios-plugins >= 2.2.1
Requires: podsec >= 0.3.1
Requires: openssh-server >= 7.8

%description nagios-plugins
A set of scripts called from the nagios server side via check_ssh plugin
to monitor and identify security threats

%prep
%setup

%build
%make_build

%install
%makeinstall_std

%pre
%_sbindir/groupadd -r -f podman &>/dev/null
%_sbindir/groupadd -r -f podman_dev &>/dev/null


%pre k8s
%_sbindir/groupadd -r -f %u7s_admin_grp &>/dev/null
%_sbindir/useradd -r -m -g %u7s_admin_grp -d %_localstatedir/%u7s_admin_usr -G systemd-journal,podman,fuse \
    -c 'usernet user account' %u7s_admin_usr  >/dev/null 2>&1 || :
if ! /bin/grep %u7s_admin_usr /etc/subuid
then
  # Сформровать /etc/subuid, /etc/subgid для системного user путем временного создания обчного пользователя
  %_sbindir/useradd -M %u7s_admin_usr_temp
  /bin/sed -e 's/%u7s_admin_usr_temp/%u7s_admin_usr/' -i /etc/subuid
  /bin/sed -e 's/%u7s_admin_usr_temp/%u7s_admin_grp/' -i /etc/subgid
  %_sbindir/userdel %u7s_admin_usr_temp
fi

%post k8s
/bin/rm -rf ~%u7s_admin_usr/.config
/bin/mv ~%u7s_admin_usr/config  ~%u7s_admin_usr/.config
mkdir -p ~%u7s_admin_usr/.config/systemd/user/multi-user.target.wants
cd ~%u7s_admin_usr/.config/systemd/user/multi-user.target.wants
/bin/ln -sf ../u7s.target  .
/bin/chown -R %u7s_admin_usr:%u7s_admin_grp ~%u7s_admin_usr
# Create u7s service
/bin/cp ~%u7s_admin_usr/usernetes/services/u7s.service /lib/systemd/system/u7s.service
mkdir -p /var/run/containerd
uid=$(id -u %u7s_admin_usr)
mkdir -p /var/run/user/$uid/usernetes/crio/
mksock /var/run/user/$uid/usernetes/crio/crio.sock;
chmod 660 /var/run/user/$uid/usernetes/crio/crio.sock
/bin/chown -R %u7s_admin_usr:%u7s_admin_grp /var/run/user/$uid
ln -sf /var/run/user/$uid/usernetes/crio/crio.sock /var/run/containerd/containerd.sock

%files
%_bindir/podsec*
%exclude %_bindir/podsec-k8s-*
%exclude %_bindir/podsec-nagios-*
%_mandir/man?/podsec*
%exclude %_mandir/man?/podsec-k8s-*
%exclude %_mandir/man?/podsec-nagios-*

%files k8s
%_bindir/podsec-k8s-*
%exclude %_bindir/podsec-k8s-rbac-*
%_mandir/man?/podsec-k8s-*
%exclude %_mandir/man?/podsec-k8s-rbac-*
%_sysconfdir/kubernetes/manifests/*
%attr(0711,%u7s_admin_usr,%u7s_admin_grp) %dir %_localstatedir/%u7s_admin_usr
%_localstatedir/%u7s_admin_usr/*
# %_localstatedir/%u7s_admin_usr/config/*
# %attr(0755,%u7s_admin_usr,%u7s_admin_grp) /home/u7s-admin/usernetes/install.sh
#%attr(0755,%u7s_admin_usr,%u7s_admin_grp) /home/u7s-admin/usernetes/*/*.sh

%files k8s-rbac
%_bindir/podsec-k8s-rbac-*
%_mandir/man?/podsec-k8s-rbac-*

%files nagios-plugins
%_libexecdir/nagios//plugins/podsec-nagios-plugins-*
%_bindir/podsec-nagios-plugins-*
%_mandir/man?/podsec-nagios-plugins-*

%changelog
* Sun Apr 09 2023 Alexey Kostarev <kaf@altlinux.org> 0.5.1-alt1
- 0.5.1

* Thu Apr 06 2023 Alexey Kostarev <kaf@altlinux.org> 0.4.1-alt1
- 0.4.1

* Wed Apr 05 2023 Alexey Kostarev <kaf@altlinux.org> 0.3.1-alt1
- 0.3.1

* Tue Mar 28 2023 Alexey Kostarev <kaf@altlinux.org> 0.2.4-alt1
- 0.2.4

* Fri Mar 24 2023 Alexey Kostarev <kaf@altlinux.org> 0.2.3-alt1
- 0.2.3

* Fri Mar 24 2023 Alexey Kostarev <kaf@altlinux.org> 0.2.2-alt1
- 0.2.2

* Sun Mar 19 2023 Alexey Kostarev <kaf@altlinux.org> 0.2.1-alt1
- 0.2.1

* Fri Mar 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.6-alt1
- 0.1.6

* Thu Mar 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.5-alt1
- 0.1.5

* Thu Mar 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.4-alt1
- 0.1.4

* Thu Mar 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.3-alt1
- 0.1.3

* Thu Mar 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.2-alt1
- 0.1.2

* Wed Mar 15 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.1-alt1
- 0.1.1

