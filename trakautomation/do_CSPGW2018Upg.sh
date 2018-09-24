#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# do_CSPGW2018Upg.sh
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

#  Upgrade to the latest version of the CSP gateway
#  Assume the GW was previously configured, quick and dirty, mostly dirty

checkPreviousConfig() {
	if [ -f /opt/cspgateway/bin/CSP.ini ]; then
		return 1
	fi
	return 0
}

checkInstaller() {
	if [ ! -f /trak/iscbuild/installers/CSPGateway-2018.1.1.643.0-lnxrhx64.tar.gz ]; then
		return 1
	fi
	return 0
}

generateConfig() {
        systemctl stop httpd
        mv /opt/cspgateway /opt/cspgateway.prepatch
        tar xzf /trak/iscbuild/installers/CSPGateway-2018.1.1.643.0-lnxrhx64.tar.gz -C /trak/iscbuild/installers/
        cd /trak/iscbuild/installers/CSPGateway-2018.1.1.643.0-lnxrhx64/install/
        echo "3
/opt/cspgateway
Y
localhost
1972
CACHE
/opt/cspgateway/cache
Y
Y
" | ./CSPinstall
        cp -pr /opt/cspgateway.prepatch/bin/CSP.ini /opt/cspgateway/bin/
	cp -pr /opt/cspgateway.prepatch/bin/CSPRT.ini /opt/cspgateway/bin/
        chown apache.root /opt/cspgateway/bin/CSP.log
	semanage fcontext -a -t httpd_sys_rw_content_t /opt/cspgateway/bin/CSP.ini
	restorecon -v /opt/cspgateway/bin/CSP.ini
	semanage fcontext -a -t httpd_sys_rw_content_t /opt/cspgateway/bin/CSPRT.ini
	restorecon -v /opt/cspgateway/bin/CSPRT.ini
	semanage fcontext -a -t httpd_log_t /opt/cspgateway/bin/CSP.log
	restorecon -v /opt/cspgateway/bin/CSP.log
        systemctl start httpd
}


echo "########################################"
echo "Upgrade CSP gateway"

if [ ! checkPreviousConfig ]; then
	echo "CSP gateway does not seems installed"
	exit 0
fi

if [ ! checkInstaller ]; then
	echo "Installer not found"
        exit 0
fi

echo "Generating configuration"
generateConfig

