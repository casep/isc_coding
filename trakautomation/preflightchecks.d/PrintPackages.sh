#!/bin/sh -e
# suggestion from LucaP
# Checks for that CUPS and hplip are installed

. ./functions.sh

check_LINUX() {
	# check CUPS
	if [ -x /usr/sbin/cupsd ]; then
		echo "=OK - Found CUPS (/usr/sbin/cupsd)"
	else
		echo "=ALERT - Expecting CUPS (/usr/sbin/cupsd) installed"
	fi
	# check hplip
	if [ -x /usr/bin/hp-info ]; then
		echo "=OK - Found hplip (/usr/bin/hp-info)"
	else
		echo "=ALERT - Expecting hplip (/usr/bin/hp-info) installed"
	fi
}

# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Print Packages"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit print $FUNCTIONS
# would have bailed above if no match
osspecific check

