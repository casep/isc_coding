#!/bin/sh -e
# installs and configures for access from all local subnets
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


check_LINUX() {
	CONF=/etc/cups/cupsd.conf
	if [ -f /usr/sbin/cupsd -a -f ${CONF}.original ]; then return 0; fi
	return 1
}

install_SLES() {
	installdepends /usr/sbin/cupsd cups
	installdepends /usr/sbin/hp-info hplip
}
install_RHEL() {
	installdepends /usr/sbin/cupsd cups
	installdepends /usr/bin/hp-info hplip
}

config_LINUX() {
	cp -a ${CONF} ${CONF}.original
	# put in network config
#	for net in `ip addr show | grep "inet .* eth[0-9]*$" | sed 's/^.* inet //' | cut -d' ' -f 1`; do
#		addr=`echo $net | cut -d/ -f1`
#		sed --in-place "/^Listen \\// i \Listen $addr:631" ${CONF}
#		subnet="$subnet `ip2netaddr $net`"
#		sed --in-place "/^<\\/Location>/ i \  Allow from $subnet" ${CONF}
#	done
	# more practical - listen on all interfaces, allow access from everwhere
	# multiple sites within a network will likely need access to administrate this
	sed --in-place 's/^\(Listen localhost:631\)/#\1/' ${CONF}
	sed --in-place "/^Listen \\// i \Listen *:631" ${CONF}
	sed --in-place "/^<\\/Location>/ i \  Allow from all" ${CONF}
	# TODO new Silver Security - we need to add trakprint group into:
	# SystemGroup sys root (in ${CONF})
	sed --in-place "s/^SystemGroup \\(.*\\)$/SystemGroup \\1 $TRAKPRINT/" ${CONF}
}

enable_LINUX() {
	chkconfig cups on
	service cups restart
}



echo "########################################"
# get it onboard
if osspecific check; then
	echo "CUPS Configuration Exists"
	exit 0
else
	echo "CUPS Install/Configuration"
	# install CUPS
	osspecific install
	# create balnk config
	osspecific config
	# enable apache
	osspecific enable
	# add dummy queues - for safety and testing
	lpadmin -p DUMMY -D 'Discards all jobs' -L 'Not a real printer' -m raw -v 'file:///dev/null' -E
	lpadmin -p DUMMY_QUEUE -D 'Discards all jobs' -L 'Not a real printer' -m raw -v 'file:///dev/null' -E
fi


