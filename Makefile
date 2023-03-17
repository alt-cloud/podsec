
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
PODSECPROGRAMMS = \
	podsec-create-imagemakeruser \
	podsec-create-podmanusers \
	podsec-create-policy \
	podsec-create-services \
	podsec-load-sign-oci \
	podsec-save-oci

PODSECFUNCTIONS = \
	podsec-functions

PODSECK8SPROGRAMS= \
	podsec-k8s-save-oci

# 	podsec-k8s-add-context \
# 	podsec-k8s-addto-kubeconfig \
# 	podsec-k8s-approve-cert \
# 	podsec-k8s-check-crt \
# 	podsec-k8s-create-csr \
# 	podsec-k8s-create-kubeconfig \
# 	podsec-k8s-create-master \
# 	podsec-k8s-csr-to-cluster

PODSECK8SMANIFESTS= \
	kube-flannel.yml

PODSECMAN1PAGES = $(PODSECPROGRAMMS:=.1)
PODSECK8SMAN1PAGES = $(PODSECK8SPROGRAMS:=.1)
MANPAGES = $(PODSECMAN1PAGES) $(PODSECK8SMAN1PAGES)

bindir = /usr/bin
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
	ls -lR
	$(MKDIR_P) -m755 $(DESTDIR)$(bindir)
	$(MKDIR_P) -m755 $(DESTDIR)$(man1dir)
	cd ./podsec/bin;$(CHMOD) 644 $(PODSECFUNCTIONS)
	cd ./podsec/bin;$(CP) $(PODSECPROGRAMMS) $(DESTDIR)$(bindir)/;
	cd ./podsec/bin;$(CP) $(PODSECFUNCTIONS) $(DESTDIR)$(bindir)/
	cd ./podsec/man;$(INSTALL) -p -m644 $(PODSECMAN1PAGES) $(DESTDIR)$(man1dir)/
	cd ./podsec-k8s/bin;$(CP) $(PODSECK8SPROGRAMS) $(DESTDIR)$(bindir)/
	cd ./podsec-k8s/man;$(INSTALL) -p -m644 $(PODSECK8SMAN1PAGES) $(DESTDIR)$(man1dir)/
	$(MKDIR_P) -m755 $(DESTDIR)/etc/kubernetes/manifests/
	cd ./podsec-k8s/manifets;$(CP) $(PODSECK8SPROGRAMS) $(DESTDIR)/etc/kubernetes/manifests/


clean:

