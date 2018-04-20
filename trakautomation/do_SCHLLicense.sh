#!/bin/bash -e
# -*- coding: utf-8 -*-
#
# do_SCHLLicense.sh
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
#
# ToDo: Any relevant check to avoud deploy it again

. ./functions.sh

if [ "$#" -eq "1" ]; then
	SVINSTNAME="$1"
else
	/bin/echo "You must supply the name of the instance to update"
	exit 1
fi

check_LINUX() {
	ERRMESSAGE="OK"
	return 1
}

install_LINUX() {
	tmpFile=/tmp/cache.key
	
	chown cacheusr.cachegrp $tmpFile
	chmod 664 $tmpFile

	/bin/cp -pf --backup $tmpFile $(ccontrol qlist | grep $SVINSTNAME | cut -d"^" -f2)/mgr/cache.key

	SVOUT=`/bin/sudo -u cachesys /bin/csession $SVINSTNAME -U %SYS << EOF
zn "%SYS"
w "",!
do ##class(%SYSTEM.License).Upgrade()
h
EOF`
	/bin/echo $SVOUT
	/bin/echo ""
	SVCHECK=$(echo $SVOUT | /bin/grep -c "1")
		if [ "${SVCHECK}" -eq "1" ]; then
			/bin/echo "SUCCESS: New license installed!"
			exit 0
		else
			/bin/echo "FAILED: New license not installed. Please check output above and fix any issues."
			exit 1
		fi
}

echo "########################################"
echo "Install Highland License"
if osspecific check; then
	/bin/echo $ERRMESSAGE
	exit 0
else
	osspecific install
fi

