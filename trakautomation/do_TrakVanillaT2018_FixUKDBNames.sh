#!/bin/sh -e
. ./functions.sh

depends_SLES() {
	echo >/dev/null
}
depends_RHEL() {
	[ -x /usr/bin/expect ] || yum install -y expect
}

echo "########################################"
INST=`instname $SITE $ENV $TYPE$VER`
TRAKNS=`traknamespace $SITE $ENV`
TRAKPATH=`trakpath $SITE $ENV $TYPE$VER`
echo "Vanilla Trak $VER DB names fix for $SITE : $ENV ($INST: $TRAKNS)"

# fix up database naming to UK convention
ccontrol stop $INST quietly
SITE_UC=`echo $SITE | tr '[:lower:]' '[:upper:]'`
sed -i "s/^$TRAKNS=$ENV-DATA,$ENV-APPSYS/$TRAKNS=$TRAKNS-DATA,$TRAKNS-APPSYS/" ${TRAKPATH}/hs/cache.cpf
sed -i "s/^$ENV-/$TRAKNS-/" ${TRAKPATH}/hs/cache.cpf
sed -i "s/\(Global_.*\|Routine_.*\|Package_.*\)=$ENV-/\1=$TRAKNS-/" ${TRAKPATH}/hs/cache.cpf

