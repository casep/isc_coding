#!/bin/sh -e
# Checks for default.htm on all the locations that should have web/ available
# ... useful to know if systems are consistent

. ./functions.sh


check_Unix() {
	# find the relevant cache.cpf in the standard path
	webdir=`trakpath $SITE $ENV DB$VER`/web
	if [ ! -d "$webdir" ]; then
		echo "=CRITICAL - can't find \"$webdir/\""
		return 0
	elif [ ! -f "$webdir/default.htm" ]; then
		echo "=ALERT - can't find \"$webdir/default.html\" - is it mounted/available?"
	else
		echo "=OK - Found \"$webdir/default.html\" as expected"
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare web/ Filesystem is Mounted/Available"
checkfieldquit TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview $FUNCTIONS

# would have bailed above if no match
osspecific check

