%define _unpackaged_files_terminate_build 1
%define u7s_admin_usr u7s-admin
%define u7s_admin_grp u7s-admin
%define kubernetes_grp kube
%define _libexecdir %_prefix/libexec
%define u7s_admin_homedir %_localstatedir/%u7s_admin_usr

Name: podsec
Version: 1.1.7
Release: alt1

Summary: Set of scripts for Podman Security
License: GPLv2+
Group: Development/Other
Url: https://github.com/alt-cloud/podsec
BuildArch: noarch

Source: %name-%version.tar

BuildRequires(pre): rpm-macros-systemd
BuildRequires(pre): libsystemd-devel
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
Requires: kubernetes-kubeadm
Requires: kubernetes-crio
Requires: cri-tools
%filter_from_requires /\/usr\/bin\/crio/d
%filter_from_requires /\/usr\/bin\/kubeadm/d
%filter_from_requires /\/usr\/bin\/kubectl/d
%filter_from_requires /\/usr\/bin\/kubelet/d
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
Requires: psmisc

%description inotify
A set of scripts for  security monitoring by systemd timers
to monitor and identify security threats

%package dev
Summary: Set of scripts for podsec developers
Group: Development/Other
Requires: podsec >= %EVR
Requires: podsec-k8s >= %EVR

%description dev
A set of scripts for developers

%package icinga
Summary: %name-inotify monitoring templates for Icinga 2
Requires: nagwad-icinga-templates >= 0.11.2
Group: Monitoring

%description icinga
Monitoring templates for Icinga 2 defining services to monitor
various Podsec events.

%package nagios
Summary: %name-inotify monitoring templates for Nagios
Requires: nagwad-nagios-templates >= 0.11.2
Group: Monitoring

%description nagios
Monitoring templates for Nagios defining services to monitor
various Podsec events.

%prep
%setup

%build
%make_build

%install
%makeinstall_std unitdir=%_unitdir modulesloaddir=%_modules_loaddir

# JSON templates are packaged using %%doc:
rm -f %buildroot%_datadir/doc/podsec/podsec-icinga2.json

%pre
groupadd -r -f podman >/dev/null 2>&1 ||:
groupadd -r -f podman_dev >/dev/null 2>&1 ||:

%pre k8s
groupadd -r -f %u7s_admin_grp  2>&1 ||:
useradd -r -M -g %u7s_admin_grp -d %u7s_admin_homedir -G %kubernetes_grp,systemd-journal,podman \
    -c 'usernet user account' %u7s_admin_usr  2>&1 ||:
# merge usernetes & podman graphroot
mkdir -p %u7s_admin_homedir/.local/share/usernetes/containers 2>&1 ||:
chown -R %u7s_admin_usr:%u7s_admin_grp %u7s_admin_homedir/.local/share/
cd %u7s_admin_homedir/.local/share
if [ -d containers ]; then mv containers containers.std; fi
ln -sf usernetes/containers . 2>&1 ||:

%post inotify
%post_systemd podsec-inotify-check-containers.service
%post_systemd podsec-inotify-check-kubeapi.service

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
%config(noreplace) %_sysconfdir/nagwad/*.sed


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


%files icinga
%doc podsec-inotify/monitoring/podsec-icinga2.json
%config(noreplace) %_sysconfdir/icinga2/conf.d/podsec.conf

%files nagios
%config(noreplace) %_sysconfdir/nagios/templates/podsec-services.cfg
%config(noreplace) %_sysconfdir/nagios/nrpe-commands/podsec-commands.cfg

%changelog
* Wed Sep 25 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.7-alt1
- Changelog of podsec.spec has been adjusted to comply with recommendations.
- Support for loading additional images into the archive.

* Tue Sep 17 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.6-alt5
- Change check policy algorithm.

* Fri Aug 23 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.6-alt4
- Fixed syntax of podsec-icinga2.json (thx Makeenkov Alexander).
- Clarified and corrected some wording in the descriptions of Nagios and Icinga events.
- Removed erroneous definition of members from the "nagwad-podsec" block of the servicegroup type.

* Wed Aug 21 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.6-alt3
- Corrected documentation for podsec-inotify scripts.
- Changes in configuration files and monitoring templates in accordance with changes in podsec/nagwad/podsec.sed.

* Tue Aug 06 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.6-alt2
- Support for multiple buckets in nagwad template - one for each podsec-inotify script.
- Correction of documentation on trivy.local domain support for c10f platform.
- Add psmisk (command fuser) dependency to package podsec-inotify.

* Sun Jul 28 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.6-alt1
- Script podsec-inotify-check-containers rewritten, man's updates.

* Thu Jul 11 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.5-alt2
- Added SyslogIdentifier to all services.

* Mon Jul 01 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.5-alt1
- Changed the format of outputting system messages via logger - script name as a tag.

* Mon Jul 01 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.4-alt1
- Completed integration of podsec-inotify scripts with nagwad, icigna2, nagios.
- Rename podsec templates for Icinga 2 and Nagios.
- Added host template "podsec-host".
- Fixed "d-nagwad-podsec" service definition.

* Mon Jul 01 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.3-alt1
- Improved podsec-inotify-check-kubeapi for correct logging.

* Fri Jun 28 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.2-alt1
- Merge rootless usernetes container catalog with podman.

* Fri Jun 28 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.1-alt1
- Changed nagwad-icigna, nagwad-nagios monitoring configuration files to support a single podsec bucket.

* Thu Jun 27 2024 Alexey Kostarev <kaf@altlinux.org> 1.1.0-alt1
- Changed message format and output format in sed template, set of 6 nagwad buckets podsec-inotify-* reduced to 1 podsec.

* Wed Jun 26 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.14-alt2
- Created universal sed template for nagwad and moved to podsec package.
- Removed podsec-nagwad package.

* Wed Jun 26 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.14-alt1
- Merge with manowar branch, add podsec-nagwad, podsec-nagwad-icinga, podsec-nagwad-nagios packages] (thnx @manowar).

* Tue Jun 25 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.13-alt1
- Configuring scripts that use tryvy to analyze images.
- Adding trivy.local to information messages and documentation.
- Added podsec-inotify/bin/podsec-inotify-build-invulnerable-image script to podsec-inotify package.
- Fix for podsec-inotify scripts that were found in shellcheck.
- Specifying the /bin/bash interpreter in the script header.
- Running the trivy server on regitry.local.
- Adding the trivy.local domain to /etc/hosts to work with the cluster trivy server.

* Wed Jun 19 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.12-alt2
- Changing priorities of system messages according to syslog.
- Correctly setting enfFile when calling podsec-u7s-functions in the root user environment.
- In podsec-inotify/bin/podsec-inotify-build-invulnerable-image added image removal in case of unsuccessful trivy completion.

* Mon Jun 17 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.12-alt1
- Added usrmerge support.

* Wed Jun 05 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.11-alt1
- Fix specification merge errors.
- Fix documentation.
- Improved script exit codes for correct operation in systemd/timers.
- Added -M Email flag to scripts, if present, the final message is sent by mail to the specified user.
- Fix BUG when generating flannel images (only loaded by default amd64).
- Eliminate situations of incorrect address transfer in checkNetCrossing.
- Fix BUG for fannel-cni-plugin.
- Remove dependency on negios.

* Tue May 28 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt10
- BUG when generating flannel images (only amd64 were loaded by default).

* Wed May 22 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt9
- Eliminate situations of incorrect address transfer in checkNetCrossing, fix BUG for fannel-cni-plugin.
- Remove dependency on negios.

* Sat Apr 27 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt8
- Removed IP address configuration code in 50-bridge.conf.
- Removed cni_net.d/50-bridge.conf to avoid setting the address 10.88.0.1 for cni0.
- Formation of a pair of flannel, flannel-cni-plugins from the tree of kube-flannel.yml files.
- Added support for U7S_CNINET, intersection analysis networks crossing, bug fixes.
- Add functions: getCniVersion, checkNetCrossing.
- Fix for /podsec-inotify-check-vuln - incorrect analysis of HIGH level errors:.
- Fixed platform detection error for c10f2.
- Added apt-get update command.
- Fixed podsec-load-sign-oci bug when working with "foreign" images.

* Thu Apr 18 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt7
- Added superuser (root) control when calling kubead@podsec-k8s, podsec-k8s-save-oci.
- If minor versions of kubeadm match, crio are not installed.
- Bug fixes.

* Tue Apr 09 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt6
- Switch to preloading images via skopeo.
- Support for correct formation of the image archive.
- Modification of podsec-k8s-save-oci, podsec-save-oci to use the getKuberImages function.
- Extraction of the u7s_images code into a separate getKuberImages() function.
- Support for the ability to write images to the archive from the local cache.
- Optimization of the algorithm for removing and installing kuber packages.
- Removing unnecessary dependencies.
- Removing the dependency on the crio package, automatic detection of the latest available image tags flannel, flannel-cni-plugin, cert-manager-controller-* and loading them.
- Added features:.
+ In the absence of the requested kuber image tags in the registrar and the presence of the U7S_SETAVAILABLEIMAGES=yes environment variable, loading the latest patch version of coredns images, pause, etcd, kube-controller-manager, kube-apiserver, kube-proxy, kube-scheduler.
+ Automatically detect the latest available image tags flannel, flannel-cni-plugin, cert-manager-controller-* and download them.
+ If the requested kuber-image tags are missing from the registrar and the environment variable U7S_SETAVAILABLEIMAGES=yes is present, download the latest patch version of the coredns, pause, etcd, kube-controller-manager, kube-apiserver, kube-proxy, kube-scheduler images.
+ Install U7S_KUBEVERSION if there is none based on the latest version in the registrar.
- Added in-depth analysis of the installed kubernetes version.
- Optimized flag analysis.

* Fri Mar 01 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt5
- To eliminate circular dependencies, the platform detection function sisyphus, p10, c10 was moved from the podsec-k8s package to the podsec package.
- Moved pause image settings from podsec to podsec-k8s.

* Mon Feb 26 2024 Alexey Shabalin <shaba@altlinux.org> 1.0.10-alt4
- Fix useradd u7s-admin.
- Fix package podsec-inotify-*.
- Support archiving the kubernetes version specified in the U7S_KUBEVERSION environment variable.
- Fixed a bug with a dependency on /etc/kubernetes/kubelet.

* Fri Feb 23 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt3
- Upgrade the default kubernetes version from 1.26.9 to 1.26.11.
- Fix conflict with /usr/lib/nagios/plugins/.
- Support for packing additional images in podsec-k8s-save-oci.

* Wed Jan 31 2024 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt2
- Add permissions to .config, ,local.
- Include in k8s package .?? directories and files.

* Tue Nov 07 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.10-alt1
- Support for installing minor versions of kubernetes packages if none are specified.
- Update MANs.
- Remove podsec-inotify-check-vuln service, switch to trivy service (server).
- Trivy-server service launch added to podsec-inotify-server-trivy service if there is a local vulnerability database /var/lib/trivy/db/trivy.db.
- Remove min_kube_minor_version from podsec.spec.
- Removed kubernetes-x.y.z-client dependency from podsec-k8s-rbac.
- Added dependencies to podsec-k8s-rbac.
- Earlier installation of packages.
- Correct formation of subcommands contents.
- Correct replacement port 80 to 81 in /etc/hosts.
- Correct processing of FLAG_control_plane_endpoint for join.
- Adding U7S_ALTREGISTRY variable.
- Clarification of flannel* versions.
- Optimization of podsec-u7s-kubeadm code.
- Moving u7s_flags to usernetes/env/.
- Editing the default version of certmanager.
- Improvements to the correct definition of the list and version of kuber images.
- Adding U7S_KUBEADFLAGS variable containing all additional kubeadm flags.
- Added analysis and processing of flags.
- Adding support for flags via getopt.
- Documenting kubeadm flags in /docs/kubead/README.md.
- Request for deletion of the /var/lib/podsec/u7s/etcd directory if it exists during init and join.
- Clarification of platform detection for sisyphus.
- More accurate automatic detection of environment variables U7S_PLATFORM, U7S_KUBEVERSION.
- Document kubeadm flags in /docs/kubeadm/README.md.
- Move tuneAudit after CNI startup, restart services after tuneAudit.
- Remove u7s.target and its dependencies.
- Replace u7s.target with /usr/libexec/podsec/u7s/bin/.
- Added kubernetes-crio dependency.
- Added kubernetes$kubeVersion-crio installation, kubernetes-crio dependency.
- Removed dependencies on kubernetes1.26-*, added dependency on kubernetes1.26-common.
- Rebind dependencies on versioned packages %min_kube_minor_version.
- Replacement in u7s-images the list of images with a call to kubeadm config images list.
- Adding config, version flags to kubeadm.
- Adding apt-get install command to replace the kubernetes and cri-o packages specified in the U7S_KUBEVERSION variable.
- Removed dependencies on kubernetes-master, kubernetes-node, flannel, etcd, there are images for this.
- Added the ability to specify U7S_PLATFORM.

* Mon Oct 30 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.9-alt1
- Added the ability to generate an image archive both before and after installing kuber.
- Using envFile during initialization after its creation instead of setRegistry.
- Universalization of the registrar name in podsec-save-oci.
- Adding the setRegistryName function.
- Refinement of the U7S_REGISTRY generation algorithm, names images.
- Formation of correct image and flannel names when working with a standard registrar.
- Transition from configuration by distribution type (k8s-p10, k8s-c10f1) to configuration by kubernetes version, including it in platform.
- Adding kubernetesVersion to config init file.
- Fixing dev/null error.
- Fixing error in flannel image version for p10.
- Redirecting connection errors when restarting kubeapi-server to /dev/null.
- Fixing error output text in podsec-load-sign-oci.
- Adding English README.md.
- Documentation in README.md has been improved with a link to https://www.altlinux.org/Rootless_kubernetes.
- Elimination of "hanging" 10.96.x.x cluster addresses on tap interfaces.

* Tue Sep 26 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.8-alt1
- Remove static cluster addresses 10.96.x.x and variable U7S_TAPIP storing this address.
- Remove allocation of static cluster IP addresses 10.96.x.x on interfaces.

* Thu Sep 21 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.7-alt1
- Remove fuse group.
- Syntax fixes.
- Separate work with /etc/cni/net.d for flannel and calico.
- Run CNI-pligins after kubeadm finishes on initMaster.
- Fix: print a newline character after the info log.
- Documentation correction.
- Support for heterogeneous clusters (RoolFullLess).
- Remove fuse group.
- Syntax fixes.
- Separate work with /etc/cni/net.d for flannel and calico.
- Start CNI-pligins after kubeadm finishes on initMaster.
- Added additional calico ports.
- Added port forwarding 5473 for calico.
- Configure the mount mode for correct calico operation.
- Adjust pod-network-cidr flag analysis.
- Move /etc/kubernetes/manifests/, audit to /etc/podsec/u7s/manifests/ to save manifests after kubeadm reset.
- Configure the mount mode for correct calico operation.
- Add environment variable U7S_CNI_PLUGIN=flannel|calico.
- Adjust pod-network-cidr flag analysis.
- Move /etc/kubernetes/manifests/, audit to /etc/podsec/u7s/manifests/ to save manifests after kubeadm reset.
- Fix: make corrections to the abstracts.
- Fix: print a newline character after the info log.
- Optimize commits.
- Removed dependency on vixie-cron, added mans to podsec-inotify.
- Create LICENSE.
- Correct documentation.
- Add LICENSE.
- Merge edits from Alexander Stepchenko's shift into podsec-u7s-kubeadm (thnx Alexander Stepchenko).
- Fix usage message, debug level detection, and command line arguments handling.
- Added scripts and timers replacing the corresponding crontabs scripts.
- Removed cron scripts.
- Added scripts and timers replacing the corresponding crontabs scripts.
- Implemented support for heterogeneous clusters (RoolFullLess).

* Tue Jul 25 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.6-alt1
- Removed dependency on vixie-cron, added man's to podsec-inotify.
- Fix: forward positional arguments to the native kubeadm.
- Fix: exit when command line arguments are incorrect.
- Fix: properly check debug level (0 <= debugLevel <= 9).
- Fix: remove option `-n` of `echo` to have a newline character at the end of line.
- Removed cron scripts.
- Added scripts and timers replacing the corresponding crontabs scripts.
- Added U7S_REGISTRY_PLATFORM environment variable.
- Replaced the remaining registry.local with U7S_REGISTRY in scripts.
- Added creation of the podman group in podman-k8s.
- Removed u7s-admin belonging to the fuse group due to the absence of this group.

* Sat Jul 15 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.5-alt1
- Implementation of the ability to install kuber from registrars other than registry.local (registry.altlinux.ru, ...).
- Removal of code implemented in usernetes/bin/_kubeadm.sh from podsec.spec.
- Setting the U7S_REGISTRY variable and its value in InitClusterConfiguration.yaml, JoinClusterConfiguration.yaml.
- Corrections of syntax errors found during testing.
- Update roadmap-20230601.md.

* Mon Jun 19 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.4-alt1
- Setting the _CONTAINERS_ROOTLESS_UID, _CONTAINERS_USERNS, _CONTAINERS_USERNS_CONFIGURED environment variables in the crio runtime for correct environment detection execution.
- The logic of podsec-inotify-check-vuln has been changed - when called from root, rootless, rootfull images are checked, when called from a regular USER - only his images.
- podsec-inotify-check-vuln - writes mail if there are any threats HIGH > Low.
- Regenerating man pages.
- Documentation directories have been moved to docs.
- Editing documentation.
- README.md formatting.
- Adding a roadmap.
- Support for archiving signed images by removing signatures.
- Checking the installed platform when loading and deploying.
- Changing the flannel version to 0.21.4.

* Fri May 26 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.3-alt1
- Universal podsec for two platforms.
- Translation of scripts for automatic platform detection and image configuration.
- Translation of scripts for configuration on the current platform - k8s-c10f1, k8s-p10.

* Fri May 26 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.2-alt1
- Changed flannel version to 0.21.4.

* Fri May 26 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.1-alt1
- Translation of scripts for configuration on the current platform - k8s-c10f1, k8s-p10.
- Correction of syntax errors in documentation and code.

* Wed May 24 2023 Alexey Kostarev <kaf@altlinux.org> 1.0.0-alt1
- Fixed flannel operation, corrected work with images and launch of nginx-deployment, al/alt image with DNS check.
- Correction of typos.
- Finalization of documentation on launching deploymants and pod's.
- Copying all plugins to /opt/cni/bin.

* Tue May 23 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.39-alt1
- Correct launch of flannel with cni-plugin.
- Cancel mounting of /opt/cni/bin directory.
- Documentation edits.

* Mon May 22 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.38-alt1
- Documentation for testing has been added.
- Support for copying keys and policy.json to a new node.
- Switch to images with the k8s-c10f1 prefix.
- Replace the k8s-p10 prefix with k8s-c10f1.
- Allocate the podsec-dev package.
- Switch from k8s-p10 to k8s-c10f1.

* Mon May 22 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.37-alt1
- Edits of /var/lib/podsec directory ownership by packages.
- Added podsec-inotify-check-images.
- Completed documentation on podsec-inotify-check-images.
- Added podsec-inotify-check-images script with crontabs.
- podsec-inotify-check-kubeapi - write last event time to separate file.
- Elimination of testers' comments.
- Transfer mail sending from cron to podsec-inotify-check-policy script.
- Completed creation and description of monitoring scripts podsec-inotify-check-kubeapi, podsec-inotify-check-policy, podsec-inotify-check-vuln.

* Fri May 19 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.36-alt1
- Added man's for monitoring scripts podsec-inotify-check-kubeapi, podsec-inotify-check-policy, podsec-inotify-check-vuln.
- Adding trivy server.
- Policy-check service has been tested.

* Fri May 19 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.35-alt1
- Policy-check service has been tested.
- Rights to etcd directory have been restored.
- Adding service file podsec-inotify-check-kubeapi.service.

* Thu May 18 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.34-alt1
- Creating additional inotify programs (podsec-inotify-check-kubeapi).
- Changing the scheme for calling programs via cron - /var/spool/crontab/root.
- Added audit of API requests.
- Created a new audit policy, fixed bugs podsec-k8s-rbac-create-kubeconfig.
- Added main audit files and functions.
- Added YAML file /etc/kubernetes/audit.policy.
- Added cron.hourly for *checkpolicy.

* Wed May 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.33-alt1
- Fix bugs, replaced extIP mask search algorithm.
- Fix bugs.
- Added podsec-inotify-check-vuln.
- Documentation revision.
- Added /usr/bin/rootlessctl script.
- Code revision, optimization, fix bugs.
- Rewrite getExtIP(), getExtDev() to work correctly with network masks.

* Tue May 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.32-alt1
- Fixed errors noticed by testers.
- support for connecting control-plane nodes !!!!!!!!!!.
- Edit service dependencies.
- Configure podsec-inotify package, add documentation, optimize scripts.
- Prepare documentation for connecting control-plane nodes.
- Configure podsec-inotify package.
- Ensured Control Plane connection.
- Split ClusterConfigurationWithEtcd.yaml into InitClusterConfiguration.yaml and JoinClusterConfiguration.yaml.
- Edits for testing department comments.
- Fix kuber version from 1.24.8 to 1.26.3.
- Display certificateKey in join master.
- Added nagios, systemd directory owners.

* Mon May 15 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.30-alt1
- Display certificateKey in join master.
- Update README.md.

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.28-alt1
- Move delegate.conf from /etc/systemd to /lib/systemd.
- Remove debug.
- Fix bugs.

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.27-alt1
- Fix notes.

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.26-alt1
- Fix notes.

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.25-alt1
- Added nagios, systemd directory owners.

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.24-alt1
- Added kubeadm flags for setting network addresses.
- Support for kubeadm join --certificate-key.
- Support for --pod-network-cidr.
- Configure Join Control Plane.
- Find the correct directory for etcd.
- Support for apiserver-advertise-address, control-plane-endpoint, service-cidr flags.

* Sun May 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.23-alt1
- Configure Join Control Plane.
- Debug kube-proxy, coredns startup after reboot.

* Fri May 12 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.22-alt1
- podsec-k8s-rbac-create-kubeconfig - take ca.crt from the usual place /etc/kubernetes/.
- Redirection 443 to 6443 after rule in PREROUTE.
- Moved usernetes.conf to /lib/modules-load.d/.
- Added wait for socket from rootlesslit service to _kubeadm.sh.
- Added wait for socket from rootlesslit service to _kubeadm.sh.
- Replaced HOME, optimized.
- Removed unimplemented podsec-inotify scripts.
- Fixes in rpm spec and Makefile.
+ Replace "mkdir -p" -> $(MKDIR_P).
+ define more variables and allow redefine over environment.
+ define _libexecdir in rpm spec.
+ define libexecdir as /usr/libexec.
+ libexecdir=/usr/libexec and nagios_plugdir=/usr/lib/nagios/plugins.

* Thu May 11 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.21-alt1
- Remove echo "PermitRootLogin yes" >> /etc/openssh/sshd_config, login with key does not require it....
- Script cleaning.
- Removed unimplemented podsec-inotify scripts.

* Thu May 11 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.20-alt1
- Added waiting for socket from rootlesslit service to _kubeadm.sh.
- Debugging missing crio.sock.

* Thu May 11 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.19-alt1
- Restore list of images in podsec-k8s-save-oci.

* Thu May 11 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.18-alt1
- Network setup.
- Redirect /dev/stderr machinectl to /dev/null.

* Wed May 10 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.17-alt1
- Removed fuse-overlays from podsec-create-imagemakeruser, podsec-create-podmanusers.

* Wed May 10 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.16-alt1
- Permissions and owner for ~u7s-admin.
- Assign user, group for .bashrc.
- Switch to 1.26.3-alt2 with group access to /etc/kubernetes.
- Support for other kubeadm flags.
- Allocate IP address and port for init apiServer.
- Adding .bashrc.
- Adding a separate YAML file for ControlPlane.
- Adding JoinControlPlane.LocalAPIEndpoint.
- Adding DNS to the algorithm for generating a static IP address (3).
- Replacing the etcd database directory with /var/lib/Etcd.
- Moving the etcd database to the standard location.
- Code optimization.

* Sun May 07 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.15-alt1
- Optimizing systemctl@u7s code.
- Added the use of templates in systemd.

* Sun May 07 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.14-alt1
- First working version after moving all files out of ~u7s-admin.
- Fixing bugs.

* Thu May 04 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.13-alt1
- Adding .sh suffix for internal scripts.
- Merge common, boot, bin into bin.
- Removed .sh prefix, optimized.
- Move config files to /etc/podsec/u7s.
- Remove unnecessary code, move user systemd services to /usr/lib/systemd/user.
- Forward ports 53 (may need to be changed according to iptables kuber).
- Providing access from cni0 interface of network 10.244.0.1/24 to external and internal announced addresses.
- Raising addresses of TAP interfaces on external interface.
- Providing launch of u7s services after sshd.service.

* Thu May 04 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.12-alt1
- Documentation, fixing issues.
- Move podsec-inotify-check-containers.service from .gear to /podsec-inotify/services/.

* Wed May 03 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.11-alt1
- Replace symlinks with real scripts, fix remaining small problems with chmod, chown, chgrp.
- Replace symlinks with real scripts, fix remaining small problems with chmod, chown, chgrp.
- Forward ports 2379, 2380, 6443, 10250, 10255, 10256 out.

* Tue May 02 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.10-alt1
- Switch to configuration composite configuration files init.yaml, join.yaml via "clean" ClusterConfigurationWithEtcd.yaml InitConfiguration.yaml JoinConfiguration.yaml KubeletConfiguration.yaml KubeProxyConfiguration.yaml.
- Provided allocation of static cluster addresses for tap0 interfaces from the range 10.96.0.0 - 10.96.155.254.
- Fixed a bug in join ControlPlane.
- Added documentation on adding a worker node.
- Adding a debug level parameter.

* Mon May 01 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.9-alt1
- Connecting workers, starting flanneld as a container.
- Separating workers, starting flanneld as a service.
- Starting flanneld as an image/pod.
- Provided support for kubeadm join for worker'а.
- Transferring iptables settings from kubeadm to rootlesskit.
- Transferring directory creation to rootlesskit.
- Removed flanneld service, we will launch it via image/pod.
- Setting up kubeadm init mode.
- Remove unused bin and boot scripts.
- Connect etcd parameters for flanneld only for controlPlane=master.
- Set up a list of pending files depending on the deployment environment (controlPlane).
- Move changing parameters controlPlane, caCertHash, token to ENV file, remove them from parameter transfers.
- Analyze kubeadm join flags and pass them to binary kubeadm.
- Use system group kube from kubernetes package.
- Switch to single script podsec-u7s-kubeadm.

* Fri Apr 28 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.8-alt1
- Switch to single script podsec-u7s-kubeadm.
- Transfer podsec-u7s-node-init, podsec-u7s-node-join to single script podsec-u7s-kubeadm.
- The password setting function has been moved to a separate script podsec-u7s-admin-passwd.
- Renaming the script podsec-u7s-create-node -> podsec-u7s-node-init, creating the script podsec-u7s-node-join and accompanying scripts in boot/ and /bin.

* Thu Apr 27 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.7-alt1
- Full deployment of the master node.
- Setting access rights to /run/flannel.
- Setting up the launch of system and --USER services.
- Added the function podsec-inotify-check-containers (thnx Nikolay Burykin).
- Modified services, removed unnecessary ones.

* Wed Apr 26 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.6-alt1
- Setting up interaction between kube-apiserver and etcd.
- Moving certificates to the standard location /etc/kubernetes/pki.
- Full configuration of the etcd service as a POD.
- Setting up kubeadm-configs/init.yaml.
- Added templates for kubeadm configuration files.
- Adding etcd and flanneld services.
- Disabling services except kubelet and rootlesskit in the no-services branch.
- Switching to Clusternet 10.96.0.0/12.
- Added setting the tap0 IP address.
- Editing the link to crio.sock.

* Mon Apr 24 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.5-alt1
- Adding the kubernetes group and editing the rights and group of the /etc/kubernetes, /etc/kubernetes/manifests/.
- Starting services after installation and reboot.

* Fri Apr 21 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.4-alt1
- First working version. kubeadm reaches the end, raises a full-fledged server.
- Copying configuration files /etc/kubernetes/*.conf from namespace u7s-admin to the main file system.
- Fine-tuning configuration files.
- Removed fuse* packages, settings for fusemount in crio.

* Fri Apr 21 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.3-alt1
- Moving scripts out of podsec.spec.
- Moving directory /var/lib/etcd to ~u7s-admin/usernetes.
- Moving creation of /run to services.
- Removing bash'isms.
- usernetes/Config -> config, initialization moved from podsec.spec to podsec-k8s/bin/podsec-u7s-create-node.

* Thu Apr 20 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.2-alt1
- Edits to podsec.spec attributes.

* Thu Apr 20 2023 Alexey Kostarev <kaf@altlinux.org> 0.9.1-alt1
- Files and directories of the podsec-nagios-plugins package have been renamed to files and directories of the podsec-inotify package.

* Thu Apr 20 2023 Alexey Kostarev <kaf@altlinux.org> 0.8.1-alt1
- First working version of deployment via kubeadm init.
- kube-scheduler.sh has been switched to reading the command and parameters from the manifest.
- FULL edit via yq of the kubelet configuration file /var/lib/kubelet/config.yaml.
- Dependencies on rootlesskit have been removed from the service, debugging has been added.
- Revert to boot/ with control uid. If uid>0 - call bin via nsenter.sh.
- Add usernetes/bin/_kubeadm.sh usernetes/bin/_kubelet.sh.

* Tue Apr 18 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.6-alt1
- Renamed services, replaced boot/*.sh calls with bin/_*sh.

* Tue Apr 18 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.5-alt1
- Renamed scripts in bin/*.sh to bin/_*.sh; systemctl waits for kubeadm to generate all manifests when starting the target service.

* Tue Apr 18 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.4-alt1
- Call format fixes, adding debugging.

* Mon Apr 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.3-alt1
- Display call format, fix errors.

* Mon Apr 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.2-alt1
- Highlight running commands under nsenter from /boot/ to /bin/.
- Move ~/bin/ to ~/usernetes/bin/, fix errors.

* Mon Apr 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.7.1-alt1
- Start of transition to kubeadm.
- Write commands from usernetes/Bin/ directory to bin/.
- Add execution permissions.
- Import etcd, kube-api-server, kube-controller-manager startup parameters from /etc/kubernetes/manifests/*.yml, adjust certificate files in flanneld.sh, kubelet.sh.
- Added boot/kubeadm.sh script calling kubeadm in nsenter environment.

* Fri Apr 14 2023 Alexey Kostarev <kaf@altlinux.org> 0.6.1-alt1
- Adjusted for new kernel 5.15.105-un-def-alt1.
- Mount etc/sysconfig/ on RW --copy-up.
- Commented out messages about existence of groups.
- Script refinement.
- Add settings to podsec.spec.
- Added mkdir -p /etc/systemd/system/user@.service.d/.
- Downgraded flannel to 1.1.2.
- Removed all images from oci archive except coredns, podsec.
- Description of current usernetes installation.
- Added password setting for u7s-admin.
- Generated and corrected the document Notes.md, CompareRootFullLess.md.
- Add authorization-mode=Node,RBAC.
- Generated and corrected the document Notes.md, CompareRootFullLess.md.
- Generated the document Notes.md.
- Added a document on how to configure kubeadm to work with rootless kuber (alt_usernetes).
- Add replacing /lib/systemd/system/kubelet.service to rootless kubelet.service.
- Add .config/systemd/user/ services.

* Sun Apr 09 2023 Alexey Kostarev <kaf@altlinux.org> 0.5.1-alt1
- Add attrs to spec.
- Added setting execution rights for *.sh.
- Removed binaries for rpm spec.
- Optimization, creating the user u7s-admin, copying usernetes to ~u7s-admin.
- Created the podsec-u7s-functions function, in which the commands for creating configuration files were moved to the createU7Environments function.
- Add alt_usernet to common development.

* Thu Apr 06 2023 Alexey Kostarev <kaf@altlinux.org> 0.4.1-alt1
- Adding scripts for alt usernetes (rootless kubernetes).

* Wed Apr 05 2023 Alexey Kostarev <kaf@altlinux.org> 0.3.1-alt1
- Adding podsec-k7s-create-node rootless kubernetes (alt_usernetes) to the spec file and Makefile, forming dependencies of kuber 1.26 packages.
- Selecting an image by prefix and discarding it to avoid duplication (loadOci).
- Switching to kubernetes 1.26 images.
- Switching to crio to the new version of pause, moving crio configuration from k8s/install/createK8S.sh to createPolicy.
- Switching to saveK8SOci.sh on image version 1.26.
- Implementation of podsec-nagios-plugins/bin/podsec-nagios-plugins-check-images.
- Specifying a remote user via @ for rootless mode.
- Switching from sudo to running the podsec-nagios-plugins-check-policy plugin as root, supplementing the documentation on configuring the plugin call on the nagios server side.
- Eliminating sudo dependency.
- Added support for LANG=C.

* Tue Mar 28 2023 Alexey Kostarev <kaf@altlinux.org> 0.2.4-alt1
- The registrar path in loadAndSignOci.sh should have the form registrar/path. Specifying the path is mandatory.
- Adding templates for new plugins.
- Correction of the algorithm for generating the name of the temporary file.
- Added plugin templates for analyzing kubernetes.
- Added the podsec-nagios-plugins-create-nagiosuser script for creating a nagios user on the client.
- Added obtaining root rights via sudo.
- Changed the plugin placement path.
- Completed documentation for the podsec-nagios-plugins-check-policy plugin.
- Completed the initial version of podsec-nagios-plugins-check-policy.
- completed mainly the first versions of the podsec podsec-k8s podsec-k8s-rbac packages.
- Fixing errors in loadAndSignOci.sh.
- Developed the main metrics of podsec-nagios-plugins-check-policy.
- Fixed the error of group formation when changing access rights to the .kube directory.
- Downgrading dependency versions to p10.
- Added functions to podsec-nagios-plugins/bin/podsec-nagios-plugins-functions and test script podsec-nagios-plugins/bin/podsec-nagios-plugins-functions-test.
- Added script podsec-nagios-plugins-create-nagiosuser to create nagios user on client.
- Added getting root rights via sudo.
- Changed plugin placement path.
- Completed documentation for podsec-nagios-plugins-check-policy.
- Completed initial version of podsec-nagios-plugins-check-policy.
- Added script templates for functions and checks in podsec-nagios-plugins, documentation for them, ....
- Configured Makefile podsec.spec to support functions in podsec-nagios-plugins/bin/podsec-nagios-plugins-functions.
- Added schemes of plugin interaction with nagios.
- Initial documentation for nagios plugins completed.
- Sudo dependency added for nagios-plugins package.

* Fri Mar 24 2023 Alexey Kostarev <kaf@altlinux.org> 0.2.3-alt1
- First versions of podsec podsec-k8s podsec-k8s-rbac packages mostly completed.
- Bug fixes in loadAndSignOci.sh.
- Developed core metrics podsec-nagios-plugins-check-policy.
- Fixed group formation error when changing access rights to .kube directory.

* Fri Mar 24 2023 Alexey Kostarev <kaf@altlinux.org> 0.2.2-alt1
- Decreased dependency versions to p10.
- Added features to podsec-nagios-plugins/bin/podsec-nagios-plugins-functions and test script podsec-nagios-plugins/bin/podsec-nagios-plugins-functions-test.
- Added script templates for functions and checks in podsec-nagios-plugins, documentation on them, ....
- Configured Makefile podsec.spec to support functions in podsec-nagios-plugins/bin/podsec-nagios-plugins-functions.
- Formatted initial version of documentation on nagios-plugins.
- Added sudo dependency for nagios-plugins package.
- Removed unformatted scripts.
- Added description of plugin call format, functionality, exit codes.
- Added podsec-nagios-plugins package to Makefile podsec.spec.
- Added function for working with nagios plugins: metricaInInterval() - Returns code 0 if metric falls within specified interval..
- Renamed script ImageSignatureVerification/checkImagesSignature.sh.
- Added author to documentation.
- Added dependencies wget and coreutils.
- Added new scripts to podsec/bin.

* Sun Mar 19 2023 Alexey Kostarev <kaf@altlinux.org> 0.2.1-alt1
- Documentation was finalized, the kubernetes API service audit setting was added in the createK8S.sh script.
- Modified Makefile, podsec.spec, removed references to unused scripts.
- Added documentation for the podsec-k8s-create-master script.
- Added documentation (in man. md format) for podsec-k8s-rbac-bindrole, podsec-k8s-rbac-create-remoteplace, podsec-k8s-rbac-get-userroles, podsec-k8s-rbac-unbindrole, modified documentation for podsec-k8s-rbac-create-kubeconfig, podsec-k8s-rbac-create-user.
- Added scripts podsec-k8s-rbac-bindrole, podsec-k8s-rbac-get-userroles, podsec-k8s-rbac-unbindrole, functions file podsec-k8s-rbac-functions, modified podsec-k8s-rbac-create-kubeconfig, podsec-k8s-rbac-create-user.
- Syntax edits of man files.
- Added commands, md- and man-files of the podsec-k8s-rbac package.

* Fri Mar 17 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.6-alt1
- Added man for podsec-k8s-create-master.
- Added manifest kube-flannel.yml.
- Added scripts podsec-k8s-save-oci, podsec-save-oci, man pages formatted, scripts modified - added checks that they are launched in the right order and on the right nodes.

* Thu Mar 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.5-alt1
- Changed the format of the list of imagemaker users - user@regPath.
- Added the ability to create multiple imagemaker class users.

* Thu Mar 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.4-alt1
- Remove /etc/kubernetes from Required, debug createImageMakerUser.sh.

* Thu Mar 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.3-alt1
- Add man pages.
- Create podsec-create-policy.md.

* Thu Mar 16 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.2-alt1
- Change directory structure: podmanbin -> podsec/bin, k8sbin -> podsec-k8s/bin.

* Wed Mar 15 2023 Alexey Kostarev <kaf@altlinux.org> 0.1.1-alt1
- Add Required to podsec, podsec-k8s.
- Add username parameters to createImageMakerUser.sh, remove apt-get install and checking list installes packages from createPolicy.sh.
- Tune Makefile, podsec.spec.
- Add changelog.
- Add gear files.
- Split bin to podmanbin, k8sbin.
- Add bin/podsec-* links.
- Removed package installation, added check for installed....
- Move archiveImages to k8s.
- Add skopeo and sigstore: to imagemaker.
- Add loadAndSignOci.sh.
- Add install skopeo.
- Add createK8S.sh and kube-flannel.yml.
- Create README.md.
- RBAC moved to k8s.
- RBAC repository moved.
- Added use of pause image for podman 4.4.2.
- Add shadow-submap package.
- Add podman package.
- Add adding groups to createPolicy.sh.
- Added entry into fuse group.
- Package installation moved to createPolicy.sh, chattr -i made recursive on all files in the directory.
- Disable http2 service.
- Service createServices.sh separated from createPodmanUsers.
- Added commands for correct configuration of rootless mode.
- Changes to 'trivy/tests/k8s/namespace'.
- Add trivy examples.
- Add createPolicy.sh.
- Universalized saveOci.sh script.
- New version of loadOci.sh.
- Written the basis of the monitorPoliciesAndImages.sh script.
- Added scripts for archiving and unarchiving (kubetnetes) images.
- Support for loading YAML files into /etc/containers/registries.d/.
- Checking config files in local user directories.
- Add noDefaultSigStore field support.
- Add support signed and notSigned images.
- Tune checkImagesSignature.sh - JSON output.
- Add checkImagesSignature.sh.
- Create 'registry/Dockerfile'.
