#!/bin/sh -e
# For edition ensure custom scripts are removed (glenpp/marcl)

. ./functions.sh


check_Unix() {
	# find the relevant cache.cpf in the standard path
	webcustomscripts=`trakpath $SITE $ENV DB$VER`/web/custom/$SITE/scripts/
	if [ ! -d "$webcustomscripts" ]; then
		echo "=OK - Custom Scripts Directory \"$webcustomscripts\" has been removed"
		return 0
	else
		echo "=ALERT - Custom Scripts Directory \"$webcustomscripts\" exists (should have been removed for Edition?)"
		return 0
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare web/custom/SITECODE/scripts/ Has been removed"
checkfieldquit TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database $FUNCTIONS

# would have bailed above if no match
osspecific check

