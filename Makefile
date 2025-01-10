
# Copyright (C) 2022  Alexey Kostarev <kaf@altlinux.org>
#
# Makefile for the podsec project.
#
# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#

PROJECT = podsec
VERSION = $(shell sed '/^Version: */!d;s///;q' gear.spec)
PODSEC_PROGRAMMS = \
	podsec-create-imagemakeruser \
	podsec-create-podmanusers \
	podsec-create-policy \
	podsec-create-services \
	podsec-load-sign-oci \
	podsec-save-oci

PODSEC_FUNCTIONS = \
	podsec-functions \
	podsec-policy-functions \
	podsec-get-platform

PODSEC_K8S_PROGRAMS= \
	podsec-k8s-save-oci \
 	podsec-u7s-kubeadm

PODSEC_K8S_FUNCTIONS = \
	podsec-u7s-functions

PODSEC_K8S_RBAC_PROGRAMS= \
	podsec-k8s-rbac-bindrole \
	podsec-k8s-rbac-create-kubeconfig \
	podsec-k8s-rbac-create-remoteplace \
	podsec-k8s-rbac-create-user \
	podsec-k8s-rbac-get-userroles \
	podsec-k8s-rbac-unbindrole

PODSEC_K8S_RBAC_FUNCTIONS = \
	podsec-k8s-rbac-functions


USERNETES_UNITS= \
	rootlesskit.service \
	kubelet.service
# 	u7s.target

USERNETES_CONFIGS= \
	cni_net.d\
	flannel  \
	env \
	ENV

USERNETES_ENVS = \
	u7s_images \
	u7s_flags

USERNETES_FUNCTIONS = \
	common/common.inc.sh

USERNETES_MANIFESTS = \
	kube-flannel.yml \
	coredns.yaml

USERNETES_KUBEADM_CONFIGS= \
	InitClusterConfiguration.yaml \
	JoinClusterConfiguration.yaml \
	InitConfiguration.yaml \
	JoinConfiguration.yaml \
	JoinControlPlaneConfijuration.yaml \
	KubeletConfiguration.yaml \
	KubeProxyConfiguration.yaml

USERNETES_KUBEADM_AUDIT= \
	policy.yaml

PODSEC_INOTIFY_PLUGINS = \
	podsec-inotify-check-policy \
	podsec-inotify-check-images

PODSEC_INOTIFY_PROGRAMMS = \
	podsec-inotify-check-containers \
	podsec-inotify-check-kubeapi \
	podsec-inotify-build-invulnerable-image \
	podsec-inotify-check-vuln

PODSEC_INOTIFY_FUNCTIONS = \
	podsec-inotify-functions

PODSEC_INOTIFY_UNITS= \
	podsec-inotify-check-containers.service \
	podsec-inotify-check-images.service \
	podsec-inotify-check-images.timer \
	podsec-inotify-check-kubeapi-mail.service \
	podsec-inotify-check-kubeapi-mail.timer \
	podsec-inotify-check-kubeapi.service \
	podsec-inotify-check-policy.service \
	podsec-inotify-check-policy.timer \
	podsec-inotify-check-vuln.service \
	podsec-inotify-check-vuln.timer

PODSEC_NAGWAD_FILTERS = \
	podsec/nagwad/podsec.sed

PODSEC_ICINGA2_CONF = \
	podsec-inotify/monitoring/podsec-icinga2.conf
PODSEC_ICINGA2_JSON = \
	podsec-inotify/monitoring/podsec-icinga2.json
PODSEC_NAGIOS_CONF = \
	podsec-inotify/monitoring/podsec-nagios.cfg
PODSEC_NRPE_CONF = \
	podsec-inotify/monitoring/podsec-nrpe.cfg

TMPFILE  := $(shell mktemp)

PODSEC_MAN1_PAGES = $(PODSEC_PROGRAMMS)
PODSEC_K8S_MAN1_PAGES = $(PODSEC_K8S_PROGRAMS)
PODSEC_K8S_RBAC_MAN1_PAGES = $(PODSEC_K8S_RBAC_PROGRAMS)
PODSEC_INOTIFY_MAN1_PAGES = $(PODSEC_INOTIFY_PLUGINS) $(PODSEC_INOTIFY_PROGRAMMS)

MANPAGES = $(PODSEC_MAN1_PAGES) $(PODSEC_K8S_MAN1_PAGES) $(PODSEC_K8S_RBAC_MAN1_PAGES)

DESTDIR ?=
prefix ?= /usr
sysconfdir ?= /etc
bindir ?= $(prefix)/bin
libexecdir ?= $(prefix)/libexec
datadir ?= $(prefix)/share
localedir ?= $(datadir)/locale/ru/LC_MESSAGES
docdir ?= $(datadir)/doc/podsec
mandir ?= $(datadir)/man
man1dir ?= $(mandir)/man1
man1rudir ?= $(mandir)/ru/man1
localstatedir ?= /var/lib
userunitdir ?= $(prefix)/lib/systemd/user
unitdir ?= /lib/systemd/system
modulesloaddir ?= /lib/modules-load.d

CP = cp -L
INSTALL = install
LN_S = ln -s
MKDIR_P = mkdir -p
TOUCH_R = touch -r
CHMOD = chmod


TARGETS = $(PROGRAMS)

.PHONY:	all install clean

all:

install: all
	# 	ls -lR
	$(MKDIR_P) -m755 $(DESTDIR)$(bindir)
	$(MKDIR_P) -m755 $(DESTDIR)$(man1dir)
	$(MKDIR_P) -m755 $(DESTDIR)$(man1rudir)

	# PODSEC
	cd ./podsec/bin;$(INSTALL) -m755 $(PODSEC_PROGRAMMS) $(DESTDIR)$(bindir)/
	cd ./podsec/bin;$(INSTALL) -m644 $(PODSEC_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec/md/en; for page in $(PODSEC_MAN1_PAGES); do ronn -r $${page}.md --pipe | xz > "$(DESTDIR)$(man1dir)/$${page}.1.xz"; done
	cd ./podsec/md/ru; for page in $(PODSEC_MAN1_PAGES); do ronn -r $${page}.md --pipe | xz > "$(DESTDIR)$(man1rudir)/$${page}.1.xz"; done
# 	cd ./podsec/man/en;$(INSTALL) -m644 $(PODSEC_MAN1_PAGES) $(DESTDIR)$(man1dir); ls -l $(DESTDIR)$(man1dir)
# 	cd ./podsec/man/ru;$(INSTALL) -m644 $(PODSEC_MAN1_PAGES) $(DESTDIR)$(man1rudir); ls -l $(DESTDIR)$(man1rudir)
	cd ./podsec/man/en;xz $(PODSEC_MAN1_PAGES); cp -f *.xz $(DESTDIR)$(man1dir);ls -l . $(DESTDIR)$(man1dir)
	cd ./podsec/man/ru;xz $(PODSEC_MAN1_PAGES); cp -f *.xz $(DESTDIR)$(man1rudir);ls -l . $(DESTDIR)$(man1rudir)
	cd ./podsec/po; msgfmt  podsec.po -o podsec.mo; $(MKDIR_P) -m755 $(DESTDIR)/$(localedir)/;$(INSTALL) -m755 podsec.mo $(DESTDIR)/$(localedir)/

	# PODSEC-K8S
	cd ./podsec-k8s/bin;$(INSTALL) -m755 $(PODSEC_K8S_PROGRAMS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s/bin;$(INSTALL) -m644 $(PODSEC_K8S_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s/md/en; for page in $(PODSEC_K8S_MAN1_PAGES); do ronn -r $${page}.md --pipe | xz > "$(DESTDIR)$(man1dir)/$${page}.1.xz"; done
	cd ./podsec-k8s/md/ru; for page in $(PODSEC_K8S_MAN1_PAGES); do ronn -r $${page}.md --pipe | xz > "$(DESTDIR)$(man1rudir)/$${page}.1.xz"; done
# 	cd ./podsec-k8s/man/en;$(INSTALL) -m644 $(PODSEC_K8S_MAN1_PAGES) $(DESTDIR)$(man1dir)/
# 	cd ./podsec-k8s/man/ru;$(INSTALL) -m644 $(PODSEC_K8S_MAN1_PAGES) $(DESTDIR)$(man1rudir)/
	cd ./podsec-k8s/man/en;xz $(PODSEC_K8S_MAN1_PAGES); cp -f *.xz $(DESTDIR)$(man1dir);ls -l . $(DESTDIR)$(man1dir)
	cd ./podsec-k8s/man/ru;xz $(PODSEC_K8S_MAN1_PAGES); cp -f *.xz $(DESTDIR)$(man1rudir);ls -l . $(DESTDIR)$(man1rudir)
	$(MKDIR_P) -m755 $(DESTDIR)$(sysconfdir)/kubernetes/manifests

	# PODSEC-K8S USERNETES
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/podsec/u7s/log/kubeapi/
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/podsec/u7s/etcd
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/u7s-admin/
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/u7s-admin/.local
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/u7s-admin/.local/share/
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/u7s-admin/.local/share/usernetes
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/u7s-admin/.local/share/usernetes/containers
	cd ./podsec-k8s/po; msgfmt  podsec-k8s.po -o podsec-k8s.mo; $(MKDIR_P) -m755 $(DESTDIR)/$(localedir)/;$(INSTALL) -m755 podsec-k8s.mo $(DESTDIR)/$(localedir)/

	# bin
	$(MKDIR_P) $(DESTDIR)$(libexecdir)/podsec/u7s/bin
	cd ./usernetes/; tar cvzf $(TMPFILE) ./bin; cd $(DESTDIR)$(libexecdir)/podsec/u7s/; tar xvzf $(TMPFILE);
	# /etc/podsec/u7s
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/podsec/u7s/config;
	cd ./usernetes/config; tar cvzf  $(TMPFILE) $(USERNETES_CONFIGS);cd $(DESTDIR)$(sysconfdir)/podsec/u7s/config;tar xvzf $(TMPFILE);
	# modules-load.
	$(MKDIR_P) $(DESTDIR)$(modulesloaddir)
	cp usernetes/config/modules-load.d/u7s.conf $(DESTDIR)$(modulesloaddir)/
	# USERNETES_ENVS
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/podsec/u7s/env
	cd usernetes/env; $(INSTALL) -m644 $(USERNETES_ENVS) $(DESTDIR)$(sysconfdir)/podsec/u7s/env
	# USERNETES_MANIFESTS
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/podsec/u7s/manifests
	cd ./usernetes/manifests/;  tar cvzf $(TMPFILE) .;  cd $(DESTDIR)$(sysconfdir)/podsec/u7s/manifests; tar xvzf $(TMPFILE);
	# USERNETES_KUBEADM_CONFIGS
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/podsec/u7s/config/kubeadm-configs
	cd ./usernetes/kubeadm-configs/; $(INSTALL) -m644 $(USERNETES_KUBEADM_CONFIGS) $(DESTDIR)$(sysconfdir)/podsec/u7s/config/kubeadm-configs
	# AUDIT POLICY
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/podsec/u7s/audit
	$(INSTALL) -m644 usernetes/audit/policy.yaml $(DESTDIR)$(sysconfdir)/podsec/u7s/audit
	# USER SYSTEMD
	$(MKDIR_P) $(DESTDIR)$(userunitdir)
	cd ./usernetes/systemd; $(INSTALL) -m644 $(USERNETES_UNITS) $(DESTDIR)$(userunitdir)
	# SYSTEMD
	$(MKDIR_P) -m755 $(DESTDIR)$(unitdir)
	$(MKDIR_P) $(DESTDIR)$(unitdir)/user@.service.d/
	$(INSTALL) -m644 usernetes/services/etc_systemd_system_user@.service.d_delegate.conf $(DESTDIR)$(unitdir)/user@.service.d/delegate.conf
	$(INSTALL) -m644 usernetes/services/u7s.service $(DESTDIR)$(unitdir)/u7s.service

	# PODSEC-K8S-RBAC
	cd ./podsec-k8s-rbac/bin;$(INSTALL) -m755 $(PODSEC_K8S_RBAC_PROGRAMS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s-rbac/bin;$(INSTALL) -m644 $(PODSEC_K8S_RBAC_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s-rbac/md/en; for page in $(PODSEC_K8S_RBAC_MAN1_PAGES); do ronn -r $${page}.md --pipe | xz > "$(DESTDIR)$(man1dir)/$${page}.1.xz"; done
	cd ./podsec-k8s-rbac/md/ru; for page in $(PODSEC_K8S_RBAC_MAN1_PAGES); do ronn -r $${page}.md --pipe | xz > "$(DESTDIR)$(man1rudir)/$${page}.1.xz"; done
# 	cd ./podsec-k8s-rbac/man/en;$(INSTALL) -m644 $(PODSEC_K8S_RBAC_MAN1_PAGES) $(DESTDIR)$(man1dir)/
# 	cd ./podsec-k8s-rbac/man/ru;$(INSTALL) -m644 $(PODSEC_K8S_RBAC_MAN1_PAGES) $(DESTDIR)$(man1rudir)/
	cd ./podsec-k8s-rbac/man/en;xz $(PODSEC_K8S_RBAC_MAN1_PAGES); cp -f *.xz $(DESTDIR)$(man1dir);ls -l . $(DESTDIR)$(man1dir)
	cd ./podsec-k8s-rbac/man/ru;xz $(PODSEC_K8S_RBAC_MAN1_PAGES); cp -f *.xz $(DESTDIR)$(man1rudir);ls -l . $(DESTDIR)$(man1rudir)
	cd ./podsec-k8s-rbac/po; msgfmt  podsec-k8s-rbac.po -o podsec-k8s-rbac.mo; $(MKDIR_P) -m755 $(DESTDIR)/$(localedir)/;$(INSTALL) -m755 podsec-k8s-rbac.mo $(DESTDIR)/$(localedir)/

	# PODSEC-INOTIFY
	cd ./podsec-inotify/bin;$(INSTALL) -m755 $(PODSEC_INOTIFY_PLUGINS) $(DESTDIR)$(bindir)/
	cd ./podsec-inotify/bin;$(INSTALL) -m755 $(PODSEC_INOTIFY_PROGRAMMS) $(DESTDIR)$(bindir)/
	cd ./podsec-inotify/bin;$(INSTALL) -m644 $(PODSEC_INOTIFY_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-inotify/md/en; for page in $(PODSEC_INOTIFY_MAN1_PAGES); do ronn -r $${page}.md --pipe | xz > "$(DESTDIR)$(man1dir)/$${page}.1.xz"; done
	cd ./podsec-inotify/md/ru; for page in $(PODSEC_INOTIFY_MAN1_PAGES); do ronn -r $${page}.md --pipe | xz > "$(DESTDIR)$(man1rudir)/$${page}.1.xz"; done
# 	cd ./podsec-inotify/man/en;$(INSTALL) -m644 $(PODSEC_INOTIFY_MAN1_PAGES) $(DESTDIR)$(man1dir)/
# 	cd ./podsec-inotify/man/ru;$(INSTALL) -m644 $(PODSEC_INOTIFY_MAN1_PAGES) $(DESTDIR)$(man1rudir)/
	cd ./podsec-inotify/man/en;xz $(PODSEC_INOTIFY_MAN1_PAGES); cp -f *.xz $(DESTDIR)$(man1dir);ls -l . $(DESTDIR)$(man1dir)
	cd ./podsec-inotify/man/ru;xz $(PODSEC_INOTIFY_MAN1_PAGES); cp -f *.xz $(DESTDIR)$(man1rudir);ls -l . $(DESTDIR)$(man1rudir)
	cd ./podsec-inotify/services;$(INSTALL) -m644 $(PODSEC_INOTIFY_UNITS) $(DESTDIR)/$(unitdir)/
	$(INSTALL) -D -m0644 $(PODSEC_ICINGA2_CONF) $(DESTDIR)$(sysconfdir)/icinga2/conf.d/podsec.conf
	$(INSTALL) -D -m0644 $(PODSEC_ICINGA2_JSON) $(DESTDIR)$(docdir)/podsec-icinga2.json
	$(INSTALL) -D -m0644 $(PODSEC_NAGIOS_CONF) $(DESTDIR)$(sysconfdir)/nagios/templates/podsec-services.cfg
	$(INSTALL) -D -m0644 $(PODSEC_NRPE_CONF) $(DESTDIR)$(sysconfdir)/nagios/nrpe-commands/podsec-commands.cfg
	for f in $(PODSEC_NAGWAD_FILTERS); do $(INSTALL) -D -m0644 $$f $(DESTDIR)$(sysconfdir)/nagwad/$${f##*/}; done
	cd ./podsec-inotify/po; msgfmt  podsec-inotify.po -o podsec-inotify.mo; $(MKDIR_P) -m755 $(DESTDIR)/$(localedir)/;$(INSTALL) -m755 podsec-inotify.mo $(DESTDIR)/$(localedir)/

clean:

