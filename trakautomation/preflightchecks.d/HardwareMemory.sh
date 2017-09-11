#!/bin/sh -e
# Checks for System Memory
# Suggestion from LucaP - often VMs are built with inappropriate memory

. ./functions.sh


check_Unix () {
	eval `Platform2ENV.pl`
	# work out requirements
	if listunion database $FUNCTIONS; then
		min=1900000
		alert=3800000
		ok=15200000
		plenty=15000000
	elif listunion app $FUNCTIONS; then
		min=1900000
		alert=3800000
		ok=7600000
		plenty=12000000
	elif listunion print $FUNCTIONS; then
		min=1900000
		alert=3800000
		ok=7600000
		plenty=12000000
	elif listunion web $FUNCTIONS; then
		min=950000
		alert=1900000
		ok=3800000
		plenty=5800000
	else
		echo "=CRITICAL - Don't have thresholds for function \"$FUNCTION\""
		return 0
	fi
	# check if we meet the requirements
	PLATFORM_memoryKB=$(($PLATFORM_memory/1024))
	if [ -z "$PLATFORM_memoryKB" ]; then
		echo "=CRITICAL - no System MemTotal found in /proc/meminfo. Is somehting wrong?"
	elif [ $PLATFORM_memoryKB -le $min ]; then
		echo "=CRITICAL - Only $PLATFORM_memoryKB kB of memory. That's not enough to do much useful."
	elif [ $PLATFORM_memoryKB -le $alert ]; then
		echo "=ALERT - Only $PLATFORM_memoryKB kB of memory. That's less than expected for any but a small test/experimenting VM"
	elif [ $PLATFORM_memoryKB -le $ok ]; then
		echo "=NOTE - Found $PLATFORM_memoryKB kB of memory. That should be good for development VMs, nothing more."
	elif [ $PLATFORM_memoryKB -ge $plenty ]; then
		echo "=OK - Found $PLATFORM_memoryKB kB of memory. That should be plenty for most sites."
	else
		echo "=OK - Found $PLATFORM_memoryKB kB of memory. That should be acceptable for the smallest sites."
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - System Memory"
#checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,web,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

