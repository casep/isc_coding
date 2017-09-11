#!/bin/sh -e
# Checks that a sane mailserver (normally Postfix) is running

. ./functions.sh


check_LINUX () {
	set +e
	service postfix status >/dev/null
	status=$?
	set -e
	if [ $status -eq 0 ]; then
		echo "=OK - Postfix is running"
	else
		echo "=ALERT - Postfix is not running... mail will not be processed"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Mail service is running"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

