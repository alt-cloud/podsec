
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
PODMANPROGRAMS = \
	podsec-create-imagemakeruser \
	podsec-create-podmanusers \
	podsec-create-policy \
	podsec-create-services \
	podsec-functions \
	podsec-load-sign-oci

K8SPROGRAMS= \
	podsec-k8s-add-context \
	podsec-k8s-addto-kubeconfig \
	podsec-k8s-approve-cert \
	podsec-k8s-check-crt \
	podsec-k8s-create-csr \
	podsec-k8s-create-kubeconfig \
	podsec-k8s-create-master \
	podsec-k8s-csr-to-cluster


bindir = /usr/bin
datadir = /usr/share
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
	$(MKDIR_P) -m755 $(DESTDIR)$(bindir)
	cd ./podmanbin;$(CP) $(PODMANPROGRAMS) $(DESTDIR)$(bindir)/
	cd ./k8sbin;$(CP) $(K8SPROGRAMS) $(DESTDIR)$(bindir)/

clean:

