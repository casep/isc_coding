#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


check_LINUX() {
	CONF=/etc/selinux/config
	if [ ! -f $CONF -o -f ${CONF}.original ]; then return 0; fi
	return 1
}

config_LINUX() {
	# backup original config
	cp -a ${CONF} ${CONF}.original
	# disable
	perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/' ${CONF}
# TODO docs say add to grub.conf: selinux=0 TODO
}


echo "########################################"
# go for it
if osspecific check; then
	echo "SELINUX Already Disabled"
	exit 0
else
	echo "SELINUX Configuration (Disable)"
	# config
	osspecific config
fi
