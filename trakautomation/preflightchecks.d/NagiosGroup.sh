#!/bin/sh -e
# Checks for the Nagios user being in cachegrp
# Without this Apache can't see Caché license files

. ./functions.sh


check_LINUX() {
	apachegroups=`groups nagios 2>/dev/null | cut -d: -f2 | sed 's/^ \+//' | sed 's/ /,/g'`
	if ! listunion cachegrp $apachegroups; then
		echo "=ALERT - Nagios user \"nagios\" not in group \"cachegrp\""
	else
		echo "=OK - Nagios user \"nagios\" found in group \"cachegrp\""
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Nagios Groups"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit web database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

