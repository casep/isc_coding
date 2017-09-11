#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


check_LinuxGen() {
	SNMPDCONF=/etc/snmp/snmpd.conf
	if [ -f ${SNMPDCONF}.original ]; then return 0; fi
	return 1
}
check_SLES() { check_LinuxGen; return $?; }
check_RHEL() { check_LinuxGen; return $?; }


# first arg is monitoring IP
config_SLES() {
	# append onto config
	echo >>${SNMPDCONF}
	echo "# ISC Config" >>${SNMPDCONF}
	echo "rocommunity public $1" >>${SNMPDCONF}
	echo "master agentx" >>${SNMPDCONF}
	echo "agentXSocket tcp:localhost:705" >>${SNMPDCONF}
}
config_RHEL() {
	sed -i 's/^\(com2sec notConfigUser \)/#isc#\1/' ${SNMPDCONF}
	echo >>${SNMPDCONF}
	echo "# ISC Config" >>${SNMPDCONF}
	echo "rocommunity public $1" >>${SNMPDCONF}
	echo "master agentx" >>${SNMPDCONF}
	echo "agentXSocket tcp:localhost:705" >>${SNMPDCONF}
}

enable_LinuxGen() {
	chkconfig snmpd on
	service snmpd start
}
enable_SLES() { enable_LinuxGen; return $?; }
enable_RHEL() { enable_LinuxGen; return $?; }




echo "########################################"
if [ $# -ne 1 ]; then
	echo "Usage: $0 <address/range for SNMP access>" >&2
	exit 1
fi
MONITORIP=$1
# configure snmpd
if osspecific check; then
	echo "snmpd Configuration Exists"
	exit 0
else
	echo "snmpd Install/Configuration"
	# install
	installdepends /usr/sbin/snmpd net-snmp
	# backup config
	cp -a ${SNMPDCONF} ${SNMPDCONF}.original
	# add config
	osspecific config $MONITORIP
	# enable and start
	osspecific enable
fi


