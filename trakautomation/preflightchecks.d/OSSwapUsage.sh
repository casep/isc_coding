#!/bin/sh -e
# Checks for Swap usage

. ./functions.sh


check_LINUX () {
	memtotal=`grep '^MemTotal: .\+ kB$' /proc/meminfo | sed 's/^.* \([0-9]\+\) .*$/\1/'`
	if [ -z "$memtotal" ]; then
		echo "=CRITICAL - no System MemTotal found in /proc/meminfo. Is somehting wrong?"
		return
	fi
	# work out total swap & usage from /etc/swaps
	totalsize=0
	totaluse=0
	while read line; do
		size=`echo $line | awk '{print $3}'`
		use=`echo $line | awk '{print $4}'`
		if [ $size == 'Size' ]; then continue; fi
		totalsize=$(($totalsize+$size))
		totaluse=$(($totaluse+$use))
	done </proc/swaps
	# work out thresholds
	reference=$memtotal
	if [ $totalsize -gt $reference ]; then reference=$totalsize; fi
	crit=$(($reference/10))
	alert=$(($reference/100))
	# check
	if [ $totalsize -eq 0 ]; then
		echo "=CRITICAL - No swap space found"
	elif [ $totaluse -eq 0 ]; then
		echo "=OK - No swap used"
	elif [ $totaluse -ge $crit ]; then
		echo "=CRITICAL - High ($totaluse KiB) of swap usage"
	elif [ $totaluse -ge $alert ]; then
		echo "=ALERT - High ($totaluse KiB) of swap usage"
	else
		echo "=NOTE - Some ($totaluse KiB) of swap usage"
	fi	
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Swap Usage"
#checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS
# would have bailed above if no match
osspecific check

