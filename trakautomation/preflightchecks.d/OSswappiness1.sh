#!/bin/sh -e
# Before bild - Checks for /proc/sys/vm/swappiness is NOT set - normally 5

. ./functions.sh


check_LINUX () {
	swappiness=`cat /proc/sys/vm/swappiness`
	if [ -z "$swappiness" ]; then
		echo "=CRITICAL - can't get value for swappiness. Is somehting wrong?"
	elif [ $swappiness -le 30 ]; then
		echo "=ALERT - unusually low swappiness level of $swappiness for a Pre CacheBuild system.... has it alredy been set?"
	else
		echo "=OK - swappiness level $swappiness is possible for Pre CacheBuild system"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Swappiness level (Pre CacheBuild)"
checkfieldquit OSSkeleton,OSHandover $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

