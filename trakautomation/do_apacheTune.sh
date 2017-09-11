#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


check_SLES() {
	APACHECONF=/etc/apache2/server-tuning.conf
	if [ -f $APACHECONF.original-do_apacheTune ]; then return 0; fi
	return 1
}
check_RHEL() {
	APACHECONF=/etc/httpd/conf/httpd.conf
	if [ -f $APACHECONF.original-do_apacheTune ]; then return 0; fi
	return 1
}

config_LinuxGen() {
	cp -an $APACHECONF $APACHECONF.original-do_apacheTune
	sed -i "s/^\\([\\t ]*ServerLimit \\+\\) [0-9]\\+$/\\1 $1/" $APACHECONF
	sed -i "s/^\\([\\t ]*MaxClients \\+\\) [0-9]\\+$/\\1 $2/" $APACHECONF
	if [ $3 -eq 0 ]; then
		sed -i "s/^\\(KeepAlive \\+\\)[^ ].*$/\\1Off/" $APACHECONF
	else
		sed -i "s/^\\(KeepAliveTimeout \\+\\) [0-9]\\+$/\\1 $3/" $APACHECONF
	fi
}
config_SLES() {
	config_LinuxGen $@
}
config_RHEL() {
	config_LinuxGen $@
}

enable_SLES() {
	service apache2 restart
}
enable_RHEL() {
	service httpd restart
}



echo "########################################"
# check for args
if [ $# -ne 3 ]; then
	echo "Usage: $0 <ServerLimit> <MaxClients> <KeepAliveTimeout>" >&2
	exit 1
fi
# get it going
if osspecific check; then
	echo "Apache Tuning Configuration Exists"
	exit 0
else
	echo "Apache Tuning Configuration"
	# sanity check values
	foundtrouble=0
	if [ $1 -lt 256 ]; then
		echo "WARNING - ServerLimit is set as $1 - this is *LOWER* than default"
		foundtrouble=1
	fi
	if [ $2 -lt 256 ]; then
		echo "WARNING - MaxClients is set as $2 - this is *LOWER* than default"
		foundtrouble=1
	fi
	if [ $2 -gt $1 ]; then
		echo "WARNING - MaxClients is set as $2 and ServerLimit is set as $1 - but MaxClients should be <= ServerLimit"
		foundtrouble=1
	fi
#	if [ $3 -eq 0 ]; then
#		# disabling keepalive
	if [ $3 -gt 5 ]; then
		echo "WARNING - KeepAliveTimeout is set as $3 - this is *HIGHER* than default"
		echo "We would expect this to be *MUCH*LOWER* than default on fast networks (LAN)"
		foundtrouble=1
	fi
	if [ $foundtrouble -eq 1 ]; then
		echo
		echo "This is abnormal tuning!"
		echo
		echo "If you actually do want this then hit Return else..."
		echo "now would be a good time to press Control-C and abort"
		read
	fi
	# set config
	osspecific config $@
	# enable new config (requires full restart)
	osspecific enable
fi


