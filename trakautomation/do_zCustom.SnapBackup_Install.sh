#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh
SCRIPTINSTALL=/opt/iscscripts



echo "########################################"
# check args
if [ -z "$1" -o $# -ne 1 ]; then
	echo "Usage: $0 <Type>" >&2
	exit 1
fi
TYPE=$1
INST=`instname $SITE $ENV $TYPE$VER`
echo "zCustom.SnapBackup Install for $SITE : $ENV ($INST)"
# get cache password if needed
if [ -z "$CACHEPASS" ]; then
	getpass "Caché Password" CACHEPASS 1
fi
# find installer
installer=`locatefilestd "zCustom.SnapBackup/zCustom.SnapBackup-*.xml"`
callin=`locatefilestd "zCustom.SnapBackup/zCustom.SnapBackup.sh"`
snaplib=`locatefilestd "zCustom.SnapBackup/snaplib.sh"`
echo "Found Class: $installer"
echo "Found Call-in: $callin"
echo "Found snaplib: $snaplib"
# install dependancies
installdepends /usr/bin/expect expect
# check that expect is available
if [ ! -x /usr/bin/expect ]; then
	echo "FATAL - can't find executable /usr/bin/expect" >&2
	exit 1
fi
# check we are root
if [ `whoami` != 'root' ]; then
	echo "Being run as user `whoami` - should be run as root"
	exit 1
fi
# install callin script
mkdirifneeded $SCRIPTINSTALL
cp $callin $SCRIPTINSTALL
cp $snaplib $SCRIPTINSTALL
chmod -x $SCRIPTINSTALL/snaplib.sh
# configure and install Caché side
./expect/zCustom.SnapBackup_Install.expect $INST $installer
# create /backup/ mountpoint area if needed
mkdirifneeded /backup


