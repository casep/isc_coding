#!/bin/sh -e
# Checks for a default route

. ./functions.sh


check_LINUX () {
	if route -n | grep -q '^0\.0\.0\.0 \+[0-9\.]\+ \+[0-9\.]\+ \+UG '; then
		echo "=OK - Appears to have a default route configred"
	else
		echo "=ALERT - No default route configured"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Defualt Route exists"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

