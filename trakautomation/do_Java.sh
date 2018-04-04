#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# do_Java.sh
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
        javaBinary=/usr/java/latest/bin/java
        if [ -f $javaBinary ]; then return 0; fi
        return 1
}

install_LINUX() {
	yum -y install jre/jre-8u161-linux-x64.rpm
	alternatives --install /usr/bin/java java /usr/java/latest/bin/java 200
	alternatives --set java /usr/java/latest/bin/java
}


echo "########################################"
echo "Install Java SUN jre"
if osspecific check; then
	echo "Java SUN jre Exists"
	exit 0
else
	osspecific install
fi


