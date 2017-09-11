#!/bin/sh -e
# Checks for eth0 present and active
# When persistent devices are not correctly handled during cloning eth0 can go away

. ./functions.sh


check_LINUX () {
	if ifconfig | grep -q '^eth0 '; then
		echo "=OK - eth0 Exists in ifconfig output"
	else
		echo "=ALERT - eth0 Not Found in ifconfig output. This could be the result of a badly cloned VM."
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - eth0 Present and Active"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

