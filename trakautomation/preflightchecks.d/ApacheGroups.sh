#!/bin/sh -e
# Checks for the Apache user being in cachegrp
# Without this Apache can't see Trak web content

. ./functions.sh


check_SLES() {
	APACHEUSER=wwwrun
	check_LinuxGen
	return $?
}
check_RHEL() {
	APACHEUSER=apache
	check_LinuxGen
	return $?
}
check_LinuxGen() {
	apachegroups=`groups $APACHEUSER | cut -d: -f2 | sed 's/^ \+//' | sed 's/ /,/g'`
	if ! listunion cachegrp $apachegroups; then
		echo "=ALERT - Apache user \"$APACHEUSER\" not in group \"cachegrp\""
	else
		echo "=OK - Apache user \"$APACHEUSER\" found in group \"cachegrp\""
	fi
}



# get on with the job
echo "*CHECK - Apache Groups"
preflightargs $@
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit web,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

