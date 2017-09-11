#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


depends_SLES() {
	echo >/dev/null
}
depends_RHEL() {
	[ -x /usr/bin/expect ] || yum install -y expect
}

findinstaller() {
	# no specific version specified - use generic
	count=`ls $1/zCustom.CheckSNMP-*.xml 2>/dev/null | wc -l`
	if [ $count -gt 1 ]; then
		echo "FATAL - found $count files matching \"$1/zCustom.CheckSNMP-*.xml\"" >&2
		return 1;
	elif [ $count -eq 0 ]; then
		return 0;
	fi
	readlink -f $1/zCustom.CheckSNMP-*.xml
	return 0
}


echo "########################################"
# check args
if [ -z "$1" -o $# -ne 1 ]; then
	echo "Usage: $0 <Type>" >&2
	exit 1
fi
TYPE=$1
INST=`instname $SITE $ENV $TYPE$VER`
echo "zCustom.CheckSNMP Install for $SITE : $ENV ($INST)"
# get cache password if needed
if [ -z "$CACHEPASS" ]; then
	getpass "Caché Password" CACHEPASS 1
fi
# find installer
checked=''
for dir in `pwd` /tmp ~ ../tools ../installers ../InstallKit; do
	installer=`findinstaller $dir`
	if [ ! -z "$installer" -a -f "$installer" ]; then break; fi
	checked="$checked $dir"
done
echo $installer
if [ -z "$installer" -o ! -f "$installer" ]; then
	echo "FATAL - can't find zCustom.CheckSNMP files in$checked directories" >&2
	exit 1
fi
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
./expect/zCustom.CheckSNMP_Install.expect $INST $installer


