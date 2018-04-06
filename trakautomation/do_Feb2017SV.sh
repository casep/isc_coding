#!/bin/bash -e
# -*- coding: utf-8 -*-
#
# do_Feb2017SV.sh
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
# ToDo: adjust $cacheusr,$cachesys$cachegrp and authentication

. ./functions.sh

if [ "$#" -eq "1" ]; then
	SVINSTNAME="$1"
else
	/bin/echo "You must supply the name of the instance to patch"
	exit 1
fi

check_LINUX() {
	SVSTATE=$(/bin/ccontrol qlist $SVINSTNAME | /bin/awk -F"^" '{print $4}' | /bin/awk -F"," '{print $1}') 
	if [ "$SVSTATE" != "running" ]; then
		ERRMESSAGE="${SVINSTNAME} instance is not running. Patch cannot be applied"
		return 0
	fi

	SVVFULLVERSION=$(/bin/ccontrol qlist $SVINSTNAME | /bin/awk -F"^" '{print $3}')
	if [ $(echo $SVVFULLVERSION | grep "Feb17SV") ]; then
		ERRMESSAGE="Patch looks already installed"
		return 0
	fi
	
	return 1
}

install_LINUX() {
	echo "wtf"
	SVVERSION=$(/bin/ccontrol qlist $SVINSTNAME | /bin/awk -F"^" '{print $3}' | /bin/awk -F"." '{print $1"."$2}')
	SVPTCHDIR=$(/bin/ccontrol qlist $SVINSTNAME | /bin/awk -F"^" '{print $2}')"/mgr/iscpatches"
	
	/bin/mkdir -p $SVPTCHDIR
	/bin/chown cacheusr:cachegrp $SVPTCHDIR 
	echo "here 1"
	if [ -f "/trak/iscbuild/installers/Feb17SV_Patch-${SVVERSION}.x-all.zip" ]; then
		/bin/cp "/trak/iscbuild/installers/Feb17SV_Patch-${SVVERSION}.x-all.zip" ${SVPTCHDIR}/
		cd ${SVPTCHDIR}/
		/bin/unzip ${SVPTCHDIR}/Feb17SV_Patch-${SVVERSION}.x-all.zip
		/bin/rm -f ${SVPTCHDIR}/Feb17SV_Patch-${SVVERSION}.x-all.zip
		SVPTCHFOLDER=$(/bin/ls ${SVPTCHDIR} | /bin/grep "${SVVERSION}.[0-9]_Feb17SV")
		echo "here"
		SVOUT=`/bin/sudo -u cachesys /bin/csession $SVINSTNAME -U %SYS << EOF
zn "%SYS"
w "",!
set iscpatch="${SVPTCHDIR}/${SVPTCHFOLDER}/syspatch_feb17sv.xml"
w "iscpatch: " _ iscpatch,!
do ##class(%SYSTEM.OBJ).Load(iscpatch)
do Apply^%SYS.PATCH
w "",!
d History^%SYS.PATCH
w "",!
h
EOF`
		/bin/echo $SVOUT
		/bin/echo ""
		SVCHECK=$(echo $SVOUT | /bin/grep -c "Patches Installed on this System Patch: Feb17SV")
		if [ "${SVCHECK}" -eq "1" ]; then
			/bin/echo "SUCCESS: Feb17SV successfully installed!"
			/bin/ccontrol update $SVINSTNAME versionid=$SVVFULLVERSION\_Feb17SV
			exit 0
		else
			/bin/echo "FAILED: Patch not installed. Please check output above and fix any issues."
			exit 1
		fi
	else
		/bin/echo "Patch file not in /trak/isbcuild/installers or doesn't match installed version: ${SVVERSION}.x"
		exit 1
	fi
}

echo "########################################"
echo "Install February 2017 SV"
if osspecific check; then
	/bin/echo $ERRMESSAGE
	exit 0
else
	osspecific install
fi
