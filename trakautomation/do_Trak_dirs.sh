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
echo "Trak Directories"
TRAKPATH=`trakpath $SITE $ENV $THISTYPE$VER`

#mkdirifneeded ${TRAKPATH}/hs true
mkdirifneeded ${TRAKPATH}/web true
#jrnbase=jrn
#for dir in jrn/ db/jrn/ hs/jrn/ ensemble/jrn/ cache/jrn/; do
#	if [ -d ${TRAKPATH}/$dir/ ]; then
#		jrnbase=$dir
#		break
#	fi
#done
#mkdirifneeded ${TRAKPATH}/$jrnbase/pri true
#mkdirifneeded ${TRAKPATH}/$jrnbase/alt true
#mkdirifneeded ${TRAKPATH}/db true
#mkdirifneeded ${TRAKPATH}/db/audit true
#mkdirifneeded ${TRAKPATH}/db/log true
mkdirifneeded ${TRAKPATH}/store/temp true
mkdirifneeded ${TRAKPATH}/patches true
mkdirifneeded ${TRAKPATH}/patches-completed true
mkdirifneeded ${TRAKPATH}/perforce true

./do_Trak_perms.sh $THISTYPE

# TODO do we need ${TRAKPATH}/store/traktemp with 777 permissions?

