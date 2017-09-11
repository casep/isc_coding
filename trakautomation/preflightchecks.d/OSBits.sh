#!/bin/sh -e
# Checks for 64-bit system

. ./functions.sh


check_Unix () {
	eval `Platform2ENV.pl`
	# check bits
	if [ -z "$PLATFORM_bits" -o -z "$PLATFORM_processor" ]; then
		echo "=CRITICAL - Processor Type or Bits not found. Is somehting wrong?"
	elif [ $PLATFORM_bits -lt 64 ]; then
		echo "=NOTE - CPU Type \"$PLATFORM_processor\" with $PLATFORM_bits-bit is not the expected 64-bit"
	elif [ $PLATFORM_bits -eq 64 ]; then
		echo "=OK - CPU Type \"$PLATFORM_processor\" with $PLATFORM_bits-bit is sane"
	else
		echo "=ALERT - CPU type \"$PLATFORM_processor\" with $PLATFORM_bits-bit is unexpected"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Machine Type"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

