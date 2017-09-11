#!/bin/sh -e
# Checks for installation of mcelog and verifies that log is zero size (no errors)

. ./functions.sh


check_LINUX () {
	if which mcelog >/dev/null 2>/dev/null; then
		echo "=OK - Found `which mcelog`"
		# check for log
		if [ ! -f /var/log/mcelog ]; then
			echo "=ALERT - /var/log/mcelog does not exist. Is mcelog running?"
		elif [ -s  /var/log/mcelog ]; then
			echo "=CRITICAL - /var/log/mcelog is non-zero size. That indicates Machine Check Exceptions logged."
		else
		echo "=OK - Found zero size /var/log/mcelog indicating no Machine Check Exceptions have occured"
		fi
	else
		echo "=ALERT - mcelog does not appear to be installed. Machine Check Exceptions will not be logged"
	fi
}

check_UNIX() {
	echo "=SKIP - would be active for Linux"
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Machine Check Exceptions (Hardware)"
# Always run
#checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS
# no need on virtual
eval `Platform2ENV.pl`
if [ -n "$PLATFORM_virtual" ]; then
	echo "=SKIP - would be active for Physical Hardware"
	exit 0
fi
# would have bailed above if no match
osspecific check

