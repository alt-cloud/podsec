
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
	modules-load.d \
	env \
	ENV

USERNETES_FUNCTIONS = \
	common/common.inc.sh

USERNETES_MANIFESTS = \
	kube-flannel.yml \
	coredns.yaml

USERNETES_KUBEADM_CONFIGS= \
	ClusterConfigurationWithEtcd.yaml \
	InitConfiguration.yaml \
	JoinConfiguration.yaml \
	KubeletConfiguration.yaml \
	KubeProxyConfiguration.yaml

PODSEC_INOTIFY_PLUGINS = \
	podsec-inotify-check-audit \
	podsec-inotify-check-images \
	podsec-inotify-check-k8s \
	podsec-inotify-check-policy \
	podsec-inotify-check-rbac \
	podsec-inotify-check-registry

PODSEC_INOTIFY_PROGRAMMS = \
	podsec-inotify-create-nagiosuser \
	podsec-inotify-check-containers

PODSEC_INOTIFY_FUNCTIONS = \
	podsec-inotify-functions \
	podsec-inotify-create-nagiosuser

TMPFILE  := $(shell mktemp)

PODSEC_MAN1_PAGES = $(PODSEC_PROGRAMMS:=.1)
PODSEC_K8S_MAN1_PAGES = $(PODSEC_K8S_PROGRAMS:=.1)
PODSEC_K8S_RBAC_MAN1_PAGES = $(PODSEC_K8S_RBAC_PROGRAMS:=.1)
PODSEC_INOTIFY_MAN1_PAGES = $(PODSEC_INOTIFY_PLUGINS:=.1) $(PODSEC_INOTIFY:=.1)

MANPAGES = $(PODSEC_MAN1_PAGES) $(PODSEC_K8S_MAN1_PAGES) $(PODSEC_K8S_RBAC_MAN1_PAGES)

bindir = /usr/bin
libexecdir = /usr/lib
datadir = /usr/share
mandir = $(datadir)/man
man1dir = $(mandir)/man1
DESTDIR =
userusnitdir=/usr/lib/systemd/user
unitdir=/lib/systemd/system


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
	$(MKDIR_P) -m755 $(DESTDIR)/etc/kubernetes/manifests/
	# PODSEC-K8S USERNETES
	mkdir -p $(DESTDIR)/var/lib/u7s-admin/
	cd usernetes; $(INSTALL) -m644 .bashrc $(DESTDIR)/var/lib/u7s-admin/
	mkdir -p $(DESTDIR)/usr/libexec/podsec/u7s/bin/
	cd usernetes;tar cvzf $(TMPFILE) bin;cd $(DESTDIR)/usr/libexec/podsec/u7s/bin/; tar xvzf $(TMPFILE);
	rm -f $(TMPFILE)
	# bin
	mkdir -p $(DESTDIR)/usr/libexec/podsec/u7s/bin
	cd ./usernetes/; tar cvzf $(TMPFILE) ./bin; cd $(DESTDIR)/usr/libexec/podsec/u7s/; tar xvzf $(TMPFILE);
	# /etc/podsec/u7s
	mkdir -p $(DESTDIR)/etc/podsec/u7s/config;
	cd ./usernetes/config; tar cvzf  $(TMPFILE) $(USERNETES_CONFIGS);cd $(DESTDIR)/etc/podsec/u7s/config;tar xvzf $(TMPFILE);
	# USERNETES_MANIFESTS
	mkdir -p $(DESTDIR)/etc/kubernetes/manifests
	cd ./usernetes/manifests/; $(INSTALL) -m644 $(USERNETES_MANIFESTS) $(DESTDIR)/etc/kubernetes/manifests
	# USERNETES_KUBEADM_CONFIGS
	mkdir -p $(DESTDIR)/etc/podsec/u7s/config/kubeadm-configs
	cd ./usernetes/kubeadm-configs/; $(INSTALL) -m644 $(USERNETES_KUBEADM_CONFIGS) $(DESTDIR)/etc/podsec/u7s/config/kubeadm-configs
	# USER SYSTEMD
	mkdir -p $(DESTDIR)$(userusnitdir)
	cd ./usernetes/systemd; $(INSTALL) -m644 $(USERNETES_UNITS) $(DESTDIR)/$(userusnitdir)
	# SYSTEMD
	mkdir -p $(DESTDIR)/etc/systemd/system/user@.service.d/
	$(INSTALL) -m644 usernetes/services/etc_systemd_system_user@.service.d_delegate.conf $(DESTDIR)/etc/systemd/system/user@.service.d/delegate.conf
	$(MKDIR_P) -m755 $(DESTDIR)$(unitdir)
	$(INSTALL) -m644 usernetes/services/u7s.service $(DESTDIR)/$(unitdir)/u7s.service
	# PODSEC-K8S-RBAC
	cd ./podsec-k8s-rbac/bin;$(INSTALL) -m755 $(PODSEC_K8S_RBAC_PROGRAMS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s-rbac/bin;$(INSTALL) -m644 $(PODSEC_K8S_RBAC_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s-rbac/man;$(INSTALL) -m644 $(PODSEC_K8S_RBAC_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	# PODSEC-NAGIOS
	$(MKDIR_P) -m755 $(DESTDIR)$(libexecdir)/nagios/plugins/
	cd ./podsec-inotify/bin;$(INSTALL) -m755 $(PODSEC_INOTIFY_PLUGINS) $(DESTDIR)$(libexecdir)/nagios/plugins/
	cd ./podsec-inotify/bin;$(INSTALL) -m755 $(PODSEC_INOTIFY_PROGRAMMS) $(DESTDIR)$(bindir)/
	cd ./podsec-inotify/bin;$(INSTALL) -m644 $(PODSEC_INOTIFY_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-inotify/man;$(INSTALL) -m644 $(PODSEC_INOTIFY_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	$(INSTALL) -m644 ./podsec-inotify/services/podsec-inotify-check-containers.service $(DESTDIR)/$(unitdir)/podsec-inotify-check-containers.service
clean:

