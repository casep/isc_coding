#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# do_Firewall.sh
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
# Quick and dirty deploy of firewall configuration files
# Works on RedHat, I don't care about Suse
# ToDo, list of ports/protocols should be a parameter

. ./functions.sh


check_LINUX() {
	if [ $(sudo systemctl status firewalld | grep running|wc -l) -eq 0 ]; then return 0 ; fi
        return 1
}

install_LINUX() {
	for port in "$@" ; do
		echo "Updating port:$port"
		firewall-cmd --zone=public --add-port=$port --permanent
	done
	firewall-cmd --reload
}

# check for args
if [ $# -ne 1 ]; then
        echo "Usage: $0 port/protocol 1972/tcp 80/tcp 443/tcp 57772/tcp 2188/tcp 4001/udp" >&2
        exit 1
fi

echo "########################################"
echo "Updating firewall configuration"

if osspecific check; then
	echo "firewalld not running"
	exit 0
else
	install_LINUX $@
fi

