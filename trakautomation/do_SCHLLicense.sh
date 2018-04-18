#!/bin/bash -e
# -*- coding: utf-8 -*-
#
# do_SCHLLicense.sh
#
#  Copyright 2018 Carlos "casep" Sepulveda <casep@fedoraproject.org>
#  Based on original script by Frank Truscot
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
	return 1
}

install_LINUX() {
	tmpFile=$(ccontrol qlist | grep $SVINSTNAME | cut -d"^" -f2)/mgr/Temp/cache.key
	
	echo "[ConfigFile]">>$tmpFile
	echo "FileType=License 2011">>$tmpFile
	echo "">>$tmpFile
	echo "[License]">>$tmpFile
	echo "LicenseCapacity=TrakCare T2012 License, PMS Core / Scotland, Concurrent Users:1000 with HealthShare Foundation 2012.2 HS4 for x86-64 (Red Hat E">>$tmpFile
	echo "CustomerName=NHS Highland">>$tmpFile
	echo "OrderNumber=201807763">>$tmpFile
	echo "ExpirationDate=4/18/2019">>$tmpFile
	echo "AuthorizationKey=412520010000010000000000000BF812F6B207626301">>$tmpFile
	echo "MachineID=">>$tmpFile
	echo "">>$tmpFile
	echo "[TrakCare]">>$tmpFile
	echo "Foundation Product=PAS, Clinical">>$tmpFile
	echo "Facility Name= \"NHS Highland\"">>$tmpFile
	echo "Facility Class=1">>$tmpFile
	echo "Concurrent Users=1000">>$tmpFile
	echo "AddOn:Active Decision Support=1">>$tmpFile
	echo "AddOn:EPR Connectivity=1">>$tmpFile
	echo "">>$tmpFile
	echo "[ISC.HealthShare]">>$tmpFile
	echo "Foundation=Enabled">>$tmpFile

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

