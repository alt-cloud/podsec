%define u7s_admin_usr u7s-admin
%define u7s_admin_grp u7s-admin
%define kubernetes_grp kube
%define _libexecdir %_prefix/libexec
%define nagiosdir %_prefix/lib/nagios
%define nagios_plugdir %nagiosdir/plugins
%define u7s_admin_homedir %_localstatedir/%u7s_admin_usr

Name: podsec
Version: 1.0.10
Release: alt3

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
Requires: pinentry-common
Requires: jq
Requires: yq
Requires: skopeo >= 1.9.1
Requires: wget
Requires: coreutils
Requires: conntrack-tools
Requires: findutils
Requires: iproute2
Requires: iptables
Requires: openssh-server
Requires: curl

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
- deploying a rootless kubernetes cluster

%package k8s
Summary: Set of scripts for Kubernetes Security
Group: Development/Other
Requires: podsec >= %EVR
Requires: rootlesskit >= 1.1.0
Requires: slirp4netns >= 1.1.12
Requires: crun >= 1.8.1
Requires: systemd-container
Requires: kubernetes-common
Requires: kubernetes-crio
Requires: cri-o
Requires: cri-tools
%filter_from_requires /\/usr\/bin\/kubeadm/d
%filter_from_requires /kubernetes-client/d
%filter_from_requires /kubernetes-kubeadm/d
%filter_from_requires /kubernetes-kubelet/d
%filter_from_requires /\/etc\/kubernetes\/kubelet/d

%description k8s
This package contains utilities for:
- deploying a rootless kubernetes cluster
- cluster node configurations

%package k8s-rbac
Summary: Set of scripts for Kubernetes RBAC
Group: Development/Other
Requires: podsec >= %EVR
Requires: openssh-common
Requires: sh

%description k8s-rbac
This package contains utilities for
- creating RBAC users
- generation of certificates and configuration files for users
- generating cluster and usual roles and binding them to users

%package inotify
Summary: Set of scripts for security monitoring
Group: Development/Other
Requires: inotify-tools
Requires: podsec >= %EVR
Requires: openssh-server
Requires: mailx
Requires: trivy
Requires: trivy-server
Requires: nagios-plugins-network
%filter_from_requires /\/usr\/lib\/nagios\/plugins\/podsec-inotify-check-images/d
%filter_from_requires /\/usr\/lib\/nagios\/plugins\/podsec-inotify-check-policy/d

%description inotify
A set of scripts for  security monitoring by systemd timers or
called from the nagios server side via check_ssh plugin
to monitor and identify security threats

%package dev
Summary: Set of scripts for podsec developers
Group: Development/Other
Requires: podsec >= %EVR
Requires: podsec-k8s >= %EVR

%description dev
A set of scripts for developers

%prep
%setup

%build
%make_build

%install
%makeinstall_std

%pre
groupadd -r -f podman >/dev/null 2>&1 ||:
groupadd -r -f podman_dev >/dev/null 2>&1 ||:

%pre k8s
groupadd -r -f podman >/dev/null 2>&1 ||:
groupadd -r -f %u7s_admin_grp  2>&1 ||:
useradd -r -m -g %u7s_admin_grp -d %u7s_admin_homedir -G %kubernetes_grp,systemd-journal,podman \
    -c 'usernet user account' %u7s_admin_usr  2>&1 ||:
chown -R %u7s_admin_usr:%u7s_admin_grp %u7s_admin_homedir
rm -rf %u7s_admin_homedir/.lpoptions \
  %u7s_admin_homedir/.mutt \
  %u7s_admin_homedir/.rpmmacros \
  %u7s_admin_homedir/.xprofile \
  %u7s_admin_homedir/.lpoptions \
  %u7s_admin_homedir/.xsession.d

%post inotify
%post_systemd podsec-inotify-check-containers.service
%post_systemd podsec-inotify-check-kubeapi.service
ln -sf %_bindir/podsec-inotify-check-policy %nagios_plugdir/
ln -sf %_bindir/podsec-inotify-check-images %nagios_plugdir/

%preun inotify
%preun_systemd podsec-inotify-check-containers.service
%preun_systemd podsec-inotify-check-kubeapi.service

%post k8s
%post_systemd  u7s.service

%preun k8s
%preun_systemd u7s.service

%files
%_bindir/podsec*
%exclude %_bindir/podsec-save-oci
%exclude %_bindir/podsec-u7s-*
%exclude %_bindir/podsec-k8s-*
%exclude %_bindir/podsec-inotify-*
%_mandir/man?/podsec*
%exclude %_mandir/man?/podsec-k8s-*
%exclude %_mandir/man?/podsec-u7s-*
%exclude %_mandir/man?/podsec-save-oci*
%exclude %_mandir/man?/podsec-inotify-*
%dir %_sysconfdir/podsec
%dir %_libexecdir/podsec
%dir %attr(0755,root,root) %_localstatedir/podsec

%files k8s
%dir %_sysconfdir/podsec/u7s
%config(noreplace) %_sysconfdir/podsec/u7s/*
%_unitdir/user@.service.d/*
%_libexecdir/podsec/u7s
%_localstatedir/podsec/u7s/*
%_modules_loaddir/u7s.conf
%_bindir/podsec-k8s-*
%_bindir/podsec-u7s-*
%exclude %_bindir/podsec-k8s-rbac-*
%exclude %_bindir/podsec-k8s-save-oci
%_mandir/man?/podsec-k8s-*
%exclude %_mandir/man?/podsec-k8s-save-oci*
%_mandir/man?/podsec-u7s-*
%exclude %_mandir/man?/podsec-k8s-rbac-*
%_unitdir/u7s.service
%_userunitdir/*
%u7s_admin_homedir/.??*
%dir %attr(0750,%u7s_admin_usr,%u7s_admin_grp) %u7s_admin_homedir
%dir %attr(0750,%u7s_admin_usr,%u7s_admin_grp) %u7s_admin_homedir/.local
%dir %attr(0750,%u7s_admin_usr,%u7s_admin_grp) %u7s_admin_homedir/.cache
%dir %attr(0750,%u7s_admin_usr,%u7s_admin_grp) %u7s_admin_homedir/.config
%dir %attr(0750,%u7s_admin_usr,%u7s_admin_grp) %u7s_admin_homedir/.ssh
%dir %attr(0750,%u7s_admin_usr,%u7s_admin_grp) %_localstatedir/podsec/u7s
%dir %attr(0750,%u7s_admin_usr,%u7s_admin_grp) %_localstatedir/podsec/u7s/etcd
%config(noreplace) %attr(0640,%u7s_admin_usr,%u7s_admin_grp) %u7s_admin_homedir/.bashrc
%config(noreplace) %attr(0640,%u7s_admin_usr,%u7s_admin_grp) %u7s_admin_homedir/.bash_profile
%config(noreplace) %attr(0640,%u7s_admin_usr,%u7s_admin_grp) %u7s_admin_homedir/.bash_logout

%files k8s-rbac
%_bindir/podsec-k8s-rbac-*
%_mandir/man?/podsec-k8s-rbac-*

%files inotify
%_bindir/podsec-inotify-*
%_mandir/man?/podsec-inotify-*
%_unitdir/podsec-inotify-*
%exclude %_unitdir/u7s.service

%files dev
%_bindir/podsec-save-oci
%_bindir/podsec-k8s-save-oci
%_mandir/man?/podsec-k8s-save-oci*
%_mandir/man?/podsec-save-oci*

%changelog
* Fri Feb 23 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt3
- 1.0.10

* Fri Feb 23 2024 Alexey Kostarev <kaf@altlinux.org> podsec.1.0.10-alt3
- podsec.1.0.10


* Wed Jan 31 2024 Alexey Kostarev <kaf@altlinux.org> 10.0.10-alt2
- 10.0.10

* Tue Nov 07 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt1
- 1.0.10

* Mon Oct 30 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.9-alt1
- 1.0.9

* Tue Sep 26 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.8-alt1
- 1.0.8

* Thu Sep 21 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.7-alt1
- 1.0.7

* Tue Jul 25 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.6-alt1
- 1.0.6

* Sat Jul 15 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.5-alt1
- 1.0.5

* Mon Jun 19 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.4-alt1
- 1.0.4


* Fri May 26 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.3-alt1
- 1.0.3

* Fri May 26 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.2-alt1
- 1.0.2

* Fri May 26 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.1-alt1
- 1.0.1

* Wed May 24 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.0-alt1
- 1.0.0

* Tue May 23 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.39-alt1
- 0.9.39

* Mon May 22 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.38-alt1
- 0.9.38

* Mon May 22 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.37-alt1
- 0.9.37

* Fri May 19 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.36-alt1
- 0.9.36

* Fri May 19 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.35-alt1
- 0.9.35

* Thu May 18 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.34-alt1
- 0.9.34

* Wed May 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.33-alt1
- 0.9.33

* Tue May 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.32-alt1
- 0.9.32

* Mon May 15 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.30-alt1
- 0.9.30

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.28-alt1
- 0.9.28

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.27-alt1
- 0.9.27

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.26-alt1
- 0.9.26

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.25-alt1
- 0.9.25

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.24-alt1
- 0.9.24

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.23-alt1
- 0.9.23

* Fri May 12 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.22-alt1
- 0.9.22

* Thu May 11 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.20-alt1
- 0.9.20

* Thu May 11 2023 Alexey Kostarev <kaf@altlinux.org> 0.0.20-alt1
- 0.0.20

* Thu May 11 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.19-alt1
- 0.9.19

* Thu May 11 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.18-alt1
- 0.9.18

* Wed May 10 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.17-alt1
- 0.9.17

* Wed May 10 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.16-alt1
- 0.9.16

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

