#!/bin/sh -e
# Checks Cache instances are all running

. ./functions.sh


check_Unix() {
	# check each instance
	founderror=0
	for inst in `cache_getinstances.pl`; do
		# ignore integrity check instances which will normally be down
		if echo $inst | grep -q INTEGRITY$; then
			# should consider if we really want this to be running
			echo "=NOTE - instance \"$inst\" appears to be an Integrity check instance - ignoring"
		else
			status=`ccontrol qlist | grep ^$inst^ | cut -d^ -f4`
			if echo "$status" | grep -vq ^running; then
				echo "=ALERT - instance \"$inst\" should likely be running"
				founderror=1
			fi
		fi
	done
	if [ $founderror = 0 ]; then
		 echo "=OK - All expected Cache instances found running"
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché Instances Running"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

