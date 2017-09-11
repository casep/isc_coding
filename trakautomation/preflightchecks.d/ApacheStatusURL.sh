#!/bin/sh -e
# Checks for that the Apache status URL is working
# This is neccessary to get stats on apache internal states and performance
# It only checks for a "Scorecard: " line in the output (normally the last line)

. ./functions.sh

check_Unix() {
	if wget --output-document=- 'http://localhost/server-status?auto' 2>/dev/null | grep -q '^Scoreboard: '; then
		echo "=OK - Expected information in downloaded status found"
	else
		 echo "=ALERT - Did not find expected status information"
	fi
}

# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Apache status URL"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit web,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

