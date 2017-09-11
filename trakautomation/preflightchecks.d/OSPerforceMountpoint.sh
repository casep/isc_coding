#!/bin/sh -e
# Checks for a dedicated mountpoint and the size of that

. ./functions.sh


check_Unix () {
	DIR=`trakpath $SITE $ENV DB$VER`/perforce
	SIZE=`df -k | grep " $DIR$" | sed 's/ \+/ /g' | cut -d' ' -f2`
	if [ -z "$SIZE" ]; then
		echo "=CRITICAL - No mountpoint found for \"$DIR\""
	elif [ $SIZE -le 2000000 ]; then
		echo "=ALERT - Only $SIZE kB for Perfroce Mountpoint \"$DIR\". This is almost certainly not enough."
	elif [ $SIZE -le 11000000 ]; then
		echo "=ALERT - Only $SIZE kB for Perfroce Mountpoint \"$DIR\". For production environments we expect 15GB (>11GB available)"
	else
		echo "=OK - Found $SIZE kB for Perfroce Mountpoint \"$DIR\". That should be plenty."
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Perforce Mountpoint"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database $FUNCTIONS
checkfieldquit UAT,TEST,PRD,DR,RR $ENV
# would have bailed above if no match
osspecific check

