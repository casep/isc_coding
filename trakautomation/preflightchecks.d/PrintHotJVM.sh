#!/bin/sh -e
# LucaP suggestion - check HotJVM

. ./functions.sh


check_LINUX () {
	set +e
	hotjvm=`ps ax| grep java | grep -- -fop-config-file`
	set -e
	if [ ! -z "$hotjvm" ]; then
		echo "=OK - HotJVM / FOP found running"
	else
		echo "=ALERT - No HotJVM / FOP found running"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - HotJVM / FOP"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit print,preview $FUNCTIONS
# would have bailed above if no match
osspecific check

