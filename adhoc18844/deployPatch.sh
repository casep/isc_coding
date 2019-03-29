#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
#  deployPatch.sh
#  
#  Copyright 2019 Carlos "casep" Sepulveda <casep@fedoraproject.org>
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

patch(){
 instancePath=$(ccontrol qlist | grep "$instance" | cut -d"^" -f2)	

 echo "Stoping instance "$instance
 runuser -l $(stat -c '%U' $instancePath/bin/cuxsession) -c "ccontrol stop $instance quietly"
 
 #Is the instance still running?
 if [ $(ccontrol qlist|grep $instance|grep -c running) -eq 1 ]
  then
  echo "Oops, instance $instance still running"
  exit 1
 fi
 
 echo ""
 echo "Backing up..."
 for backupFile in cache cstat cwdimj libcache.so libcachet.so
  do
   echo "Backing up "$backupFile
   \cp -p $instancePath/bin/$backupFile $instancePath/bin/$backupFile.old
 done

 echo "Backing up cache.o"
 \cp -p $instancePath/dev/cache/callin/samples/cache.o $instancePath/dev/cache/callin/samples/cache.o.old

 echo ""
 echo "Applying patches"
 for newFile in cache.exe cstat cwdimj libcache.so libcachet.so
  do
  echo "Copying "$newFile
  \cp $patchPath/lnxrhx64/unicode/$newFile $instancePath/bin/
 done

 mv $instancePath/bin/cache.exe $instancePath/bin/cache
 chown $(stat -c '%U' $instancePath/bin/cache.old).$(stat -c '%G' $instancePath/bin/cache.old) $instancePath/bin/cache
 chmod $(stat -c '%a' $instancePath/bin/cache.old) $instancePath/bin/cache
 
 echo "Copying cache.o"
 \cp $patchPath/lnxrhx64/unicode/cache.o $instancePath/dev/cache/callin/samples/

 echo "Starting instance "$instance
 runuser -l $(stat -c '%U' $instancePath/bin/cuxsession) -c "ccontrol start $instance quietly"

 ccontrol update $instance versionid=2017.2.1.801.3.18514_18844

 #Is the instance still running?
 if [ $(ccontrol qlist|grep $instance|grep -c down) -eq 1 ]
  then
  echo "Oops, instance $instance is not running"
  echo "Apply CacheSYSUpdate18844 manually"
  exit 1
 fi
 
 echo "zn \"%SYS\" d ^DATABASE
2
$instancePath/mgr/cachelib
14
No

Yes
Yes


d \$system.OBJ.Load(\"/tmp/CacheSYSUpdate18844.xml\",\"cbrpsuy\")
d ^DATABASE
2
$instancePath/mgr/cachelib
14
Yes

Yes
Yes


h"|runuser -l $(stat -c '%U' $instancePath/bin/cuxsession) -c "csession $instance -U %SYS"

}

if [ ! -f /tmp/Patch-2017.2.1.801.3.18844-unix.tar.gz ]
 then
  echo "No patch available"
  exit 1
fi

tar xzf /tmp/Patch-2017.2.1.801.3.18844-unix.tar.gz -C /tmp/
patchPath="/tmp/adhoc18844"

if [ ! -f $patchPath/lnxrhx64/unicode/cache.exe ]
 then
  echo "Patch not extracted correctly"
  exit 1
fi

ccontrol qlist | cut -d"^" -f1 | while read instance
 do
  patch instance
 done
