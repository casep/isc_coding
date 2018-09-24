#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# do_Patch18375.sh
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
# Quick and dirty deploy of 18375 adhoc, work only for one instance, atm
# Works on RedHat, I don't care about Suse

checkInstaller() {
        if [ ! -f /trak/iscbuild/installers/adhoc18375/Syspatch18375.xml ]; then
                return 1
        fi
        return 0
}

deployPatch() {
echo "Patching"
echo "zn \"%SYS\" d ^DATABASE
2
$(ccontrol qlist | cut -d"^" -f2)/mgr/cachelib
14
No

Yes
Yes


d \$system.OBJ.Load(\"/trak/iscbuild/installers/adhoc18375/Syspatch18375.xml\",\"fck\")
d Apply^%SYS.PATCH
d ^DATABASE
2
$(ccontrol qlist | cut -d"^" -f2)/mgr/cachelib
14
Yes

Yes
Yes


h"|su - cachesys -c "csession $(ccontrol qlist | cut -d"^" -f1)"

}

updateVersion() {
	echo "Updating version id"
	ccontrol update $(ccontrol qlist | cut -d"^" -f1) versionid=$(ccontrol qlist | cut -d"^" -f3)\_"18375"
}

if [ ! checkInstaller ]; then
        echo "Installer not found"
        exit 0
fi

echo "########################################"
echo "Deploy 18375 Patch"

deployPatch
updateVersion
