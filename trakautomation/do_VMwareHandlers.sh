#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# do_VMwareHandlers.sh
#
#  Copyright 2018 Carlos "casep" Sepulveda <casep@fedoraproject.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
# Quick and dirty deploy of Apache configuration files
# Works on RedHat, I don't care about Suse

. ./functions.sh


check_LINUX() {
        preThawScript=/usr/sbin/pre-freeze-script
        if [ -f $preThawScript ]; then return 0; fi
        return 1
}

install_LINUX() {
	mkdir /etc/admin
	cp -pr zCustom.SnapBackup /etc/admin/CacheUtil
	ln -s /etc/admin/CacheUtil/pre-freeze-script /usr/sbin/
	ln -s /etc/admin/CacheUtil/post-thaw-script /usr/sbin/
	touch /var/log/vmware_snapshot.log
	chmod 666 /var/log/vmware_snapshot.log
	echo "Test, as root, /usr/sbin/pre-freeze-script"
	echo "Test, as root, /usr/sbin/post-thaw-script"

}


echo "########################################"
echo "Install VCB and pre-freeze/post-thaw scripts in Linux VMs"
if osspecific check; then
	echo "VCB and pre-freeze/post-thaw scripts Exists"
	exit 0
else
	osspecific install
fi


