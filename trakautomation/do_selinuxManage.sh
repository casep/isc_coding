#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# do_selinuxManage.sh
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

TRAKPATH=`trakpath $SITE $ENV $TYPE$VER`

check_LINUX() {
	if [ ! -f /usr/sbin/semanage ]; then return 0 ; fi
        return 1
}

install_LINUX() {
	semanage fcontext -a -t httpd_sys_rw_content_t /opt/cspgateway/bin/CSP.ini
	restorecon -v /opt/cspgateway/bin/CSP.ini
	semanage fcontext -a -t httpd_sys_rw_content_t /opt/cspgateway/bin/CSPRT.ini
	restorecon -v /opt/cspgateway/bin/CSPRT.ini
	semanage fcontext -a -t httpd_log_t /opt/cspgateway/bin/CSP.log
	restorecon -v /opt/cspgateway/bin/CSP.log

	semanage fcontext -a -t httpd_sys_rw_content_t "$TRAKPATH/web(/.*)?"
	restorecon -Rv "$TRAKPATH/web/"
	semanage fcontext -a -t httpd_sys_rw_content_t "$TRAKPATH/perforce(/.*)?"
	restorecon -Rv /trak/scgcBASE/tc/perforce/
	ccontrol qlist | cut -d"^" -f6 | while read superPort; do
		semanage port -a -t http_port_t -p tcp $superPort
	done
	setsebool -P httpd_can_network_connect 1
}

echo "########################################"
echo "Updating selinux configuration"
if osspecific check; then
	echo "semanage not installed"
	exit 0
else
	install_LINUX
fi



