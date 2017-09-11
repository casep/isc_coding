#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


depends_LINUX() {
	installdepends /usr/bin/expect expect
}



echo "########################################"
# check args
if [ -z "$1" -o $# -ne 1 ]; then
	echo "Usage: $0 <Type>" >&2
	exit 1
fi
TYPE=$1
INST=`instname $SITE $ENV $TYPE$VER`
echo "TrakCare SysAdminTasks for $SITE : $ENV ($INST)"
# get cache password if needed
if [ -z "$CACHEPASS" ]; then
	getpass "Caché Password" CACHEPASS 1
fi
# prepare dirs
[ -d /var/TCMon ] || mkdir /var/TCMon
chown $CACHEUSR:$CACHEGRP /var/TCMon
chmod 750 /var/TCMon
# install dependancies
osspecific depends
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
# configure and install Caché side
NS=`echo $SITE | tr '[:lower:]' '[:upper:]'`-`echo $ENV | sed 's/[0-9]*$//'`
./expect/SysAdminTasks+TCMon.expect $INST $NS


