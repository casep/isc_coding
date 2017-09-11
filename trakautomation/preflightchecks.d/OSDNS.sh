#!/bin/sh -e
# Checks for sane ServerLimit, MaxClients and KeepAliveTimeout
# With inappropriate setting performancy may be poor to the point that service is lost

. ./functions.sh


check_LINUX () {
	CONF=/etc/resolv.conf
	if grep -q '^nameserver [0-9a-fA-F]' $CONF; then
		echo "=OK - Appears to have a DNS server configred"
	else
		echo "=ALERT - No DNS server configured"
	fi
	if grep -q '^search [^ ]' $CONF; then
		echo "=OK - Appears to have a \"search\" domain configred"
	else
		echo "=ALERT - No \"search\" domain configred"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - DNS Config"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

