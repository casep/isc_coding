#!/bin/sh -e
# Post build - Checks for /proc/sys/vm/swappiness - normally 5

. ./functions.sh


check_LINUX () {
	swappiness=`cat /proc/sys/vm/swappiness`
	if [ -z "$swappiness" ]; then
		echo "=CRITICAL - can't get value for swappiness. Is somehting wrong?"
	elif [ $swappiness -le 5 ]; then
		echo "=OK - swappiness level $swappiness is sane for a built system"
	elif [ $swappiness -le 10 ]; then
		echo "=NOTE - swappiness level $swappiness higher than expected for a built system, but probably ok"
	else
		echo "=ALERT - unusually high swappiness level of $swappiness for a built system"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Swappiness level (Post CacheBuild)"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

