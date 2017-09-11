#!/bin/sh -e
# Checks for that the CUPS has a Listen config matching *:631 or <hostname/IP>:631

. ./functions.sh

check_LINUX() {
	CONF=/etc/cups/cupsd.conf
	if [ ! -f $CONF ]; then
		echo "=CRITICAL - CUPS Config \"$CONF\" doesn't exist"
		return 0
	fi
	# collect up possible addresses
	set +e
	hostname=`hostname | cut -d. -f1`
	fqdn=`hostname -f 2>/dev/null`
	hostip=`host -t A $hostname | sed 's/^.* //' | grep -v NXDOMAIN`
	ifconfig=`ifconfig | grep 'inet addr:' | sed 's/^.*inet addr://' | cut -d' ' -f1 | grep -v '127\.0\.0\.1'`
	listenaddresses="$hostname $fqdn $hostip $ifconfig"
	set -e
	# count up matching Listen lines
	count=0
	for config in `grep -i ^Listen $CONF | cut -d' ' -f2`; do
		for addr in $listenaddresses '*'; do
			if [ "$config" = "$addr:631" ]; then
				count=$(($count+1))
			fi
		done
	done
	if [ $count -gt 0 ]; then
		echo "=OK - Got $count \"Listen\" lines matching local addresses"
	else
		echo "=ALERT - Found no \"Listen\" lines matching local addresses"
	fi
	
}

# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - CUPS Listen"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit print $FUNCTIONS
# would have bailed above if no match
osspecific check

