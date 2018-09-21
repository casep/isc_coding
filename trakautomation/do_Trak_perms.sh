#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh

if [ -n "${TYPE+1}" ]; then
  THISTYPE=$TYPE
else
  THISTYPE=DB
fi

if [ $# -ge 1 ]; then
	case $1 in
		DB|APP*|PRT*|ANALYTICS|INTEGRATION|INTEGRITY*|SHADOW|REPORTING|CSP|LABDB)
		THISTYPE=$1
		;;
		*)
		THISTYPE=DB
		;;
	esac
fi


echo "########################################"
echo "Trak Permissions (basic)"
TRAKPATH=`trakpath $SITE $ENV $THISTYPE$VER`

# New owner for db and how the 2018 installer is run
chown $CACHESYSUSR.$CACHEGRP ${TRAKPATH}/db
chmod 775 ${TRAKPATH}/db

# setting sgid to encourage the correct group to be used
chown $CACHEUSR.$CACHEGRP ${TRAKPATH}/web
chmod 2770 ${TRAKPATH}/web

# setting sgid to encourage correct group - remaining perms from MarkB's Linux Install doc
chown $CACHEUSR.$CACHEGRP ${TRAKPATH}/store/temp
chmod -R 2770 ${TRAKPATH}/store/temp


# setting sgid to encourage the correct group to be used
chown $CACHEUSR.$CACHEGRP ${TRAKPATH}/patches*
chmod -R 2770 ${TRAKPATH}/patches*

# set permissions on backup/ if it exists
if [ -d ${TRAKPATH}/backup/ ]; then
	chown root.$CACHEGRP ${TRAKPATH}/backup/
	chmod 2750 ${TRAKPATH}/backup/
fi

# set permissions on perforce/ if it exists
if [ -d ${TRAKPATH}/perforce/ ]; then
	chown $CACHEUSR.$CACHEGRP ${TRAKPATH}/perforce/
	chmod 2770 ${TRAKPATH}/perforce/
fi

