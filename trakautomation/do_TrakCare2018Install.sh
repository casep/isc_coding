#!/bin/bash
# -*- coding: utf-8 -*-
#
# do_TrakCare2018Install.sh
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
# ToDo: 

if [ "$#" -eq "9" ]; then
	INSTALLER="$1"
	EXTRACTPATH="$2"
	INSTNAME="$3"
	DBDIR="$4"
	ENV="$5"
	NAMESPACE="$6"
	TRAKDIR="$7"
	WEBDIR="$8"
	WEBURL="$9"
else
	/bin/echo "Usage: $0 <PATH TO TRAKCARE INSTALLER> <INSTALLER EXTRACT PATH> <INSTANCE> <DB DIR> <ENV> <NAMESPACE> <TRAKDIR> <WEBDIR> <WEBURL>"
	exit 1
fi

/usr/bin/mkdir -p $EXTRACTPATH
if [ ! -d $EXTRACTPATH ]; then
	/bin/echo "Error creating extract path"
	exit 1	
fi

/bin/unzip $INSTALLER -d $EXTRACTPATH

/bin/sudo -u $CACHESYSUSR /bin/csession $INSTNAME -U"USER" << EOF
do $system.OBJ.Load("$EXTRACTPATH/tkutils.xml","fc")
s vars("APPSYS-DB")="APPSYS"
s vars("CREATEANLTNAMESPACE")="No"
s vars("DATA-DB")="DATA"
s vars("DBDIR")=$DBDIR
s vars("ENV")=$ENV
s vars("NAMESPACE")=$NAMESPACE
s vars("OTHER-DB")="ANALYTICS,AUDIT0,AUDIT1,CT,FACTS,HISTORYLOGS,HL7,IKNOW,LABDATA,LOCALENS,LOG0,LOG1,MONITOR,RESULTCACHE,SYSCONFIG,ZTEMP,DOCUMENT,DOCUMENT-ANNOTATE,DOCUMENT-AVI,DOCUMENT-BMP,DOCUMENT-DCM,DOCUMENT-DOC,DOCUMENT-GIF,DOCUMENT-HTM,DOCUMENT-JPG,DOCUMENT-MPG,DOCUMENT-PDF,DOCUMENT-PNG,DOCUMENT-RTF,DOCUMENT-TIF,DOCUMENT-TXT,DOCUMENT-WAV,DOCUMENT-WMA,DOCUMENT-WMV"
s vars("OVERWRITE")="Yes"
s vars("RUNSECURITY")="Yes"
s vars("RUNUPDATEDOC")="No"
s vars("SRCDIR")=$SRCDIR
s vars("STARTNS")="USER"
s vars("TRAKDIR")=$TRAKDIR
s vars("WEBDIR")=$WEBDIR
s vars("WEBURL")=$WEBURL"/"
s vars("ANALYTICS-APPSYS")="ANLT-APPSYS"
s vars("ANALYTICS-CODE")="ANLT"
s vars("ANALYTICS-OTHER-DB")="ANLT-ANALYTICS,ANLT-FACTS,ANLT-HISTORYLOGS,ANLT-LOCAL,ANLT-LOCALSYS,ANLTRESULTCACHE"
s vars("ANLTWEBDIR")=$WEBDIR
s vars("ANLTWEBURL")=$WEBURL"analytics/"
do setup^tkutils(.vars)
#Do you want to continue : (Y/N) ?
Yes
h
EOF

