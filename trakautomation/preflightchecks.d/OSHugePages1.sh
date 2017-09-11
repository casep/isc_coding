#!/bin/sh -e
# Pre build - Checks for HugePages configuration

. ./functions.sh


check_LINUX () {
	# collect info
	memtotal=`grep '^MemTotal: .\+ kB$' /proc/meminfo | sed 's/^.* \([0-9]\+\) .*$/\1/'`
	hugepagesize=`grep '^Hugepagesize: .\+ kB$' /proc/meminfo | sed 's/^.* \([0-9]\+\) .*$/\1/'`
	hugepages=`grep '^HugePages_Total: .\+$' /proc/meminfo | sed 's/^.* \([0-9]\+\)$/\1/'`
	if [ -z "$memtotal" ]; then
		echo "=CRITICAL - no System MemTotal found in /proc/meminfo. Is somehting wrong?"
		return
	fi
	if [ -z "$hugepagesize" -o -z "$hugepages" ]; then
		echo "=CRITICAL - no System Hugepagesize/HugePages_Total found in /proc/meminfo. Is somehting wrong?"
		return
	fi
	if [ $hugepages -gt 0 ]; then
		echo "=ALERT - Not expecting HugePages to be configured at this stage (Pre CacheBuild), but $hugepages are set."
	else
		echo "=OK - No HugePages are configured at this stage (Pre CacheBuild)."
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - HugePages (Pre CacheBild)"
checkfieldquit OSSkeleton,OSHandover $STAGE
checkfieldquit database,app,print,perview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

