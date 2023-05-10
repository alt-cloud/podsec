%define u7s_admin_usr u7s-admin
%define u7s_admin_grp u7s-admin
%define kubernetes_grp kube

Name: podsec
Version: 0.9.15
Release: alt1

Summary: Set of scripts for Podman Security
License: GPLv2+
Group: Development/Other
Url: https://github.com/alt-cloud/podsec
BuildArch: noarch

Source: %name-%version.tar

BuildRequires(pre): rpm-macros-systemd
Requires: podman >= 4.4.2
Requires: shadow-submap >= 4.5
Requires: nginx >= 1.22.1
Requires: docker-registry >= 2.8.1
Requires: pinentry-common >= 1.1.0
Requires: jq >= 1.6
Requires: yq >= 2.12.2
Requires: skopeo >= 1.9.1
Requires: sh >= 4.4.23
Requires: wget >= 1.21.3
Requires: coreutils >= 8.32.0
Requires: conntrack-tools >= 1.4.6
Requires: findutils >= 4.8.0
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
Requires: kubernetes-kubeadm >= 1.26.3-alt2
Requires: kubernetes-kubelet >= 1.26.3-alt2
Requires: kubernetes-crio >= 1.26.3-alt2
Requires: kubernetes-master >= 1.26.3-alt2
Requires: kubernetes-node >= 1.26.3-alt2
Requires: etcd >= 3.4.15
Requires: flannel >= 0.13.0
# Requires: flannel >= 0.19.2
Requires: cni-plugin-flannel >= 1.1.2
#Requires: cni-plugin-flannel >= 1.2.0
Requires: rootlesskit >= 1.1.0
Requires: slirp4netns >= 1.1.12
Requires: crun >= 1.8.1
Requires: cri-o >= 1.26.2
Requires: cri-tools >= 1.22.0
Requires: kubernetes-client >= 1.26.3-alt2
Requires: systemd-container >= 249.16
%filter_from_requires /\/etc\/kubernetes\/kubelet/d

%description k8s
This package contains utilities for:
- cluster node configurations

%package k8s-rbac
Summary: Set of scripts for Kubernetes RBAC
Group: Development/Other
Requires: kubernetes-client >= 1.26.3-alt2
Requires: podsec >= 0.3.1
Requires: curl >= 7.88.0


%description k8s-rbac
This package contains utilities for
- creating RBAC users
- generation of certificates and configuration files for users
- generating cluster and usual roles and binding them to users

%package inotify
Summary: Set of scripts for security monitoring
Group: Development/Other
Requires: inotify-tools >= 3.20
Requires: podsec >= 0.3.1
Requires: openssh-server >= 7.8

%description inotify
A set of scripts for  security monitoring by crontabs or
called from the nagios server side via check_ssh plugin
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
%_sbindir/useradd -r -m -g %u7s_admin_grp -d %_localstatedir/%u7s_admin_usr -G %kubernetes_grp,systemd-journal,podman,fuse \
    -c 'usernet user account' %u7s_admin_usr  >/dev/null 2>&1 || :
echo "export PATH=/usr/libexec/podsec/u7s/bin/:$PATH" >> ~%u7s_admin_usr/.bash_profile

%preun
%preun_systemd podsec-inotify-check-containers.service
%preun_systemd u7s.service

%files
%_bindir/podsec*
%exclude %_bindir/podsec-u7s-*
%exclude %_bindir/podsec-k8s-*
%exclude %_bindir/podsec-inotify-*
%exclude %_libexecdir/nagios/plugins/podsec-inotify-*
%_mandir/man?/podsec*
%exclude %_mandir/man?/podsec-k8s-*
%exclude %_mandir/man?/podsec-u7s-*
%exclude %_mandir/man?/podsec-inotify-*

%files k8s
/usr/libexec/podsec/u7s/*
%_bindir/podsec-k8s-*
%_bindir/podsec-u7s-*
%exclude %_bindir/podsec-k8s-rbac-*
%_unitdir/u7s.service
%_mandir/man?/podsec-k8s-*
%_mandir/man?/podsec-u7s-*
%_userunitdir/*
%_sysconfdir/podsec/u7s/*
/usr/libexec/podsec/u7s/*
%exclude %_mandir/man?/podsec-k8s-rbac-*
%_sysconfdir/systemd/system/*
%_sysconfdir/kubernetes/manifests/*
%_unitdir/*
/usr/lib/systemd/user/*
/var/lib/u7s-admin/.bashrc

%files k8s-rbac
%_bindir/podsec-k8s-rbac-*
%_mandir/man?/podsec-k8s-rbac-*

%files inotify
%_libexecdir/nagios/plugins/podsec-inotify-*
%_bindir/podsec-inotify-*
%_mandir/man?/podsec-inotify-*
%attr(-,root,root) %_libexecdir/nagios/
%attr(-,root,root) %_libexecdir/nagios/*
%_unitdir/podsec-inotify-check-containers.service

%changelog
* Sun May 07 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.15-alt1
- 0.9.15

* Sun May 07 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.14-alt1
- 0.9.14

* Thu May 04 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.12-alt1
- 0.9.12

* Wed May 03 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.11-alt1
- 0.9.11

* Tue May 02 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.10-alt1
- 0.9.10

* Mon May 01 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.9-alt1
- 0.9.9

* Fri Apr 28 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.8-alt1
- 0.9.8

* Thu Apr 27 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.7-alt1
- 0.9.7

* Wed Apr 26 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.6-alt1
- 0.9.6

* Mon Apr 24 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.5-alt1
- 0.9.5

* Mon Apr 24 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.6-alt1
- 0.9.6

* Fri Apr 21 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.4-alt1
- 0.9.4

* Fri Apr 21 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.3-alt1
- 0.9.3

* Thu Apr 20 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.2-alt1
- 0.9.2

* Thu Apr 20 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.3-alt1
- 0.9.3

* Thu Apr 20 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.2-alt1
- 0.9.2

* Thu Apr 20 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.1-alt1
- 0.9.1

* Thu Apr 20 2023 Alexey Kostarev <kaf@altlinux.org> 0.8.1-alt1
- 0.8.1

* Tue Apr 18 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.6-alt1
- 0.7.6

* Tue Apr 18 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.5-alt1
- 0.7.5

* Tue Apr 18 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.4-alt1
- 0.7.4

* Mon Apr 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.3-alt1
- 0.7.3

* Mon Apr 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.2-alt1
- 0.7.2

* Mon Apr 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.1-alt1
- 0.7.1

* Fri Apr 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.6.1-alt1
- 0.6.1

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

