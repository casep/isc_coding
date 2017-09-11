#!/bin/sh -e
# Checks mail to root actually goes somewhere... hopefully someone will get it and be looking at it

. ./functions.sh


check_LINUX () {
	if grep -q ^root: /etc/aliases; then
		echo "=OK - Alias for \"root\" found. Not checking it's a valid destination"
	elif [ -f /root/.forward ]; then
		echo "=OK - Found .foward file for \"root\". Not checking it's a valid destination"
	else
		echo "=ALERT - No Alias for \"root\" found so many system messages (eg. from Cron) will fill up a local mail spool which most likely nobody will look at"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Mail to root"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

