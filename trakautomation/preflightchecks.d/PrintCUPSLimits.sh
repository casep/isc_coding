#!/bin/sh -e
# Checks for that the CUPS MaxJobs is set to > 500, preferably >= 2000
# Based on suggestion from LucaP 20130322

. ./functions.sh

check_Unix() {
	CONF=/etc/cups/cupsd.conf
	if [ ! -f $CONF ]; then
		echo "=CRITICAL - CUPS Config \"$CONF\" doesn't exist"
		return 0
	fi
	# check for the limits
	value=`grep '^MaxJobs ' $CONF | sed 's/^MaxJobs \+//'`
	if [ -z "$value" ]; then
		echo "=ALERT - MaxJobs is not set"
	elif [ $value -le 500 ]; then
		echo "=ALERT - MaxJobs of $value is lower than default of 500"
	elif [ $value -lt 2000 ]; then
		echo "=NOTE - MaxJobs of $value is lower than would be expected on a production site"
	else
		# prsumably its 2000 or more then
		echo "=OK - MaxJobs of $value is sane"
	fi
	
}

# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - CUPS Limits"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit print $FUNCTIONS
# would have bailed above if no match
osspecific check

