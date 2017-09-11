#!/bin/sh -e
# Checks for SHM=OS in [SYSTEM] section of CSP.ini
# Without this CSP Gateway causes SEVGs on Graceful Restart (reload)
# See WRC 787301

. ./functions.sh


check_LINUX() {
	set +e
	setting=`ini_getparam.pl /opt/cspgateway/bin/CSP.ini SYSTEM SHM 2>/dev/null`
	set -e
	if [ -z "$setting" ]; then
		echo "=ALERT - Expected [SYSTEM]->SHM=NONE config NOT found which may result in Apache SEGV after Graceful Restart or crash with Backtrace in error_log (Based on 2012.x & 2013.x versions)"
	elif [ $setting = 'NONE' ]; then
		echo "=OK - Expected [SYSTEM]->SHM=NONE config found"
	else
		echo "=ALERT - [SYSTEM]->SHM=$setting which may result in Apache SEGV Graceful Restart crash with Backtrace in error_log (Based on 2012.x & 2013.x versions)"
	fi
}
check_AIX() {
	# behaves the same as Linux so just run that
	check_LINUX
}
check_Unix() {
	echo "=NOTE - check not done for platforms other than SUSE, Red Hat and AIX as no reports of problems (yet)"
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - possibly bad CSP SHM config"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit web,preview,analytics $FUNCTIONS
checkfieldquit 2010,2011,2012,2013 $VER
# would have bailed above if no match
osspecific check

