
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
	podsec-policy-functions

PODSEC_K8S_PROGRAMS= \
	podsec-k8s-save-oci \
 	podsec-k8s-create-master \
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
	kubelet.service \
	u7s.target

USERNETES_CONFIGS= \
	cni_net.d\
	flannel  \
	env \
	ENV

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
	podsec-inotify-check-policy

PODSEC_INOTIFY_PROGRAMMS = \
	podsec-inotify-check-containers \
	podsec-inotify-check-kubeapi \
	podsec-inotify-check-vuln

PODSEC_INOTIFY_FUNCTIONS = \
	podsec-inotify-functions

PODSEC_INOTIFY_CRON_PROGRAMS= \
	podsec-inotify-check-policy \
	podsec-inotify-check-vuln \
	podsec-inotify-check-kubeapi

TMPFILE  := $(shell mktemp)

PODSEC_MAN1_PAGES = $(PODSEC_PROGRAMMS:=.1)
PODSEC_K8S_MAN1_PAGES = $(PODSEC_K8S_PROGRAMS:=.1)
PODSEC_K8S_RBAC_MAN1_PAGES = $(PODSEC_K8S_RBAC_PROGRAMS:=.1)
PODSEC_INOTIFY_MAN1_PAGES = $(PODSEC_INOTIFY_PLUGINS:=.1) $(PODSEC_INOTIFY:=.1)

MANPAGES = $(PODSEC_MAN1_PAGES) $(PODSEC_K8S_MAN1_PAGES) $(PODSEC_K8S_RBAC_MAN1_PAGES)

DESTDIR =
prefix ?= /usr
sysconfdir ?= /etc
bindir ?= $(prefix)/bin
libexecdir ?= $(prefix)/libexec
datadir ?= $(prefix)/share
mandir ?= $(datadir)/man
man1dir ?= $(mandir)/man1
localstatedir ?= /var/lib
userunitdir ?= $(prefix)/lib/systemd/user
unitdir ?= /lib/systemd/system
nagios_plugdir ?= $(prefix)/lib/nagios/plugins

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
	# PODSEC
	cd ./podsec/bin;$(INSTALL) -m755 $(PODSEC_PROGRAMMS) $(DESTDIR)$(bindir)/
	cd ./podsec/bin;$(INSTALL) -m644 $(PODSEC_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec/man;$(INSTALL) -m644 $(PODSEC_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	# PODSEC-K8S
	cd ./podsec-k8s/bin;$(INSTALL) -m755 $(PODSEC_K8S_PROGRAMS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s/bin;$(INSTALL) -m644 $(PODSEC_K8S_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s/man;$(INSTALL) -m644 $(PODSEC_K8S_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	$(MKDIR_P) -m755 $(DESTDIR)$(sysconfdir)/kubernetes/manifests
	# PODSEC-K8S USERNETES
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/podsec/u7s/log/kubeapi/
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/podsec/u7s/etcd
	$(MKDIR_P) $(DESTDIR)$(localstatedir)/u7s-admin/
	cd usernetes; $(INSTALL) -m644 .bashrc $(DESTDIR)$(localstatedir)/u7s-admin/
	# bin
	$(MKDIR_P) $(DESTDIR)$(libexecdir)/podsec/u7s/bin
	cd ./usernetes/; tar cvzf $(TMPFILE) ./bin; cd $(DESTDIR)$(libexecdir)/podsec/u7s/; tar xvzf $(TMPFILE);
	# /etc/podsec/u7s
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/podsec/u7s/config;
	cd ./usernetes/config; tar cvzf  $(TMPFILE) $(USERNETES_CONFIGS);cd $(DESTDIR)$(sysconfdir)/podsec/u7s/config;tar xvzf $(TMPFILE);
	# modules-load.
	$(MKDIR_P) $(DESTDIR)//lib/modules-load.d/
	cp usernetes/config/modules-load.d/u7s.conf $(DESTDIR)/lib/modules-load.d/
	# USERNETES_MANIFESTS
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/kubernetes/manifests
	cd ./usernetes/manifests/; $(INSTALL) -m644 $(USERNETES_MANIFESTS) $(DESTDIR)$(sysconfdir)/kubernetes/manifests
	# USERNETES_KUBEADM_CONFIGS
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/podsec/u7s/config/kubeadm-configs
	cd ./usernetes/kubeadm-configs/; $(INSTALL) -m644 $(USERNETES_KUBEADM_CONFIGS) $(DESTDIR)$(sysconfdir)/podsec/u7s/config/kubeadm-configs
	# AUDIT POLICY
	$(MKDIR_P) $(DESTDIR)$(sysconfdir)/kubernetes/audit
	$(INSTALL) -m644 usernetes/audit/policy.yaml $(DESTDIR)$(sysconfdir)/kubernetes/audit
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
	cd ./podsec-k8s-rbac/man;$(INSTALL) -m644 $(PODSEC_K8S_RBAC_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	# PODSEC-NAGIOS
	$(MKDIR_P) -m755 $(DESTDIR)$(nagios_plugdir)
	cd ./podsec-inotify/bin;$(INSTALL) -m755 $(PODSEC_INOTIFY_PLUGINS) $(DESTDIR)$(nagios_plugdir)/
	cd ./podsec-inotify/bin;$(INSTALL) -m755 $(PODSEC_INOTIFY_PROGRAMMS) $(DESTDIR)$(bindir)/
	cd ./podsec-inotify/bin;$(INSTALL) -m644 $(PODSEC_INOTIFY_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-inotify/man;$(INSTALL) -m644 $(PODSEC_INOTIFY_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	$(INSTALL) -m644 ./podsec-inotify/services/podsec-inotify-check-containers.service $(DESTDIR)/$(unitdir)/podsec-inotify-check-containers.service
	# CRONTAB SERVICRS
	$(MKDIR_P) -m755 $(DESTDIR)$(sysconfdir)/podsec/crontabs
	cd ./podsec-inotify/crontabs;$(INSTALL) -m755 $(PODSEC_INOTIFY_CRON_PROGRAMS) $(DESTDIR)/$(sysconfdir)/podsec/crontabs


clean:

