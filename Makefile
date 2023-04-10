
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

PODSEC_K8S_MANIFESTS= \
	kube-flannel.yml

PODSEC_K8S_PROGRAMS= \
	podsec-k8s-save-oci \
 	podsec-k8s-create-master \
 	podsec-u7s-create-node

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

USERNETES_PROGRAMMS = \
	install.sh \
	uninstall.sh \
	rootlessctl.sh \
	boot/*.sh \
	services/* \
	config/*

USERNETES_FUNCTIONS = \
	common/common.inc.sh \
	manifests/coredns.yaml

PODSEC_NAGIOS_PLUGINS = \
	podsec-nagios-plugins-check-audit \
	podsec-nagios-plugins-check-images \
	podsec-nagios-plugins-check-k8s \
	podsec-nagios-plugins-check-policy \
	podsec-nagios-plugins-check-rbac \
	podsec-nagios-plugins-check-registry

PODSEC_NAGIOS_PLUGINS_FUNCTIONS = \
	podsec-nagios-plugins-functions \
	podsec-nagios-plugins-create-nagiosuser

TMPFILE  := $(shell mktemp)

PODSEC_MAN1_PAGES = $(PODSEC_PROGRAMMS:=.1)
PODSEC_K8S_MAN1_PAGES = $(PODSEC_K8S_PROGRAMS:=.1)
PODSEC_K8S_RBAC_MAN1_PAGES = $(PODSEC_K8S_RBAC_PROGRAMS:=.1)
PODSEC_NAGIOS_PLUGINS_MAN1_PAGES = $(PODSEC_NAGIOS_PLUGINS:=.1) podsec-nagios-plugins-create-nagiosuser.1

MANPAGES = $(PODSEC_MAN1_PAGES) $(PODSEC_K8S_MAN1_PAGES) $(PODSEC_K8S_RBAC_MAN1_PAGES)

bindir = /usr/bin
libexecdir = /usr/lib
datadir = /usr/share
mandir = $(datadir)/man
man1dir = $(mandir)/man1
DESTDIR =

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
	cd ./podsec/bin;$(CHMOD) 644 $(PODSEC_FUNCTIONS)
	cd ./podsec/bin;$(CP) $(PODSEC_PROGRAMMS) $(DESTDIR)$(bindir)/;
	cd ./podsec/bin;$(CP) $(PODSEC_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec/man;$(INSTALL) -p -m644 $(PODSEC_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	# PODSEC-K8S
	cd ./podsec-k8s/bin;$(CP) $(PODSEC_K8S_PROGRAMS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s/bin;$(CP) $(PODSEC_K8S_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s/man;$(INSTALL) -p -m644 $(PODSEC_K8S_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	$(MKDIR_P) -m755 $(DESTDIR)/etc/kubernetes/manifests/
	cd ./podsec-k8s/manifests/;$(CP) $(PODSEC_K8S_MANIFESTS) $(DESTDIR)/etc/kubernetes/manifests/
	# PODSEC-K8S USERNETES
	mkdir -p $(DESTDIR)/var/lib/u7s-admin/.local $(DESTDIR)/var/lib/u7s-admin/usernetes
	cd usernetes;$(CHMOD) 644 $(USERNETES_FUNCTIONS);
	cd usernetes;tar cvzf $(TMPFILE) $(USERNETES_FUNCTIONS) ;cd $(DESTDIR)/var/lib/u7s-admin/usernetes; tar xvzf $(TMPFILE);
	cd usernetes;tar cvzf $(TMPFILE) $(USERNETES_PROGRAMMS);cd $(DESTDIR)/var/lib/u7s-admin/usernetes; tar xvzf $(TMPFILE)
	cd usernetes; $(CP) -r Config  $(DESTDIR)/var/lib/u7s-admin/config
	rm -f $(TMPFILE)
	# PODSEC-K8S-RBAC
	cd ./podsec-k8s-rbac/bin;$(CP) $(PODSEC_K8S_RBAC_PROGRAMS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s-rbac/bin;$(CP) $(PODSEC_K8S_RBAC_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s-rbac/man;$(INSTALL) -p -m644 $(PODSEC_K8S_RBAC_MAN1_PAGES) $(DESTDIR)$(man1dir)/
	# PODSEC-NAGIOS
	$(MKDIR_P) -m755 $(DESTDIR)$(libexecdir)/nagios/plugins/
	cd ./podsec-nagios-plugins/bin;$(CP) $(PODSEC_NAGIOS_PLUGINS) $(DESTDIR)$(libexecdir)/nagios/plugins/
	cd ./podsec-nagios-plugins/bin;$(CP) $(PODSEC_NAGIOS_PLUGINS_FUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec-nagios-plugins/man;$(INSTALL) -p -m644 $(PODSEC_NAGIOS_PLUGINS_MAN1_PAGES) $(DESTDIR)$(man1dir)/

clean:

