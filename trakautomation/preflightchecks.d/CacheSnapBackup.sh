#!/bin/sh -e
# Checks For zCustom.SnapBackup scripts in /opt/iscscripts/ and Cache instances below scripts/

. ./functions.sh


check_Unix() {
	# do we get the script in the usual place
	scriptcount=0
	if [ -f /opt/iscscripts/zCustom.SnapBackup.sh ]; then
		echo "=OK - Found System-Wide backup script \"/opt/iscscripts/zCustom.SnapBackup.sh\""
		scriptcount=$(($scriptcount+1))
	else
		echo "=NOTE - No System-Wide backup script \"/opt/iscscripts/zCustom.SnapBackup.sh\", checking each instance"
		# check through each instance
		for instance in `cache_getinstances.pl`; do
			path=`cache_instance2path.pl "$instance"`
			if [ -f "$path/scripts/zCustom.SnapBackup.sh" ]; then
				echo "=OK - Found Instance Specific backup script \"$path/scripts/zCustom.SnapBackup.sh\""
				scriptcount=$(($scriptcount+1))
			else
				echo "=NOTE - No Instance Specific backup script \"$path/scripts/zCustom.SnapBackup.sh\""
			fi
		done
	fi
	if [ $scriptcount -eq 0 ]; then
		echo "=ALERT - No backup script \"zCustom.SnapBackup.sh\" found in the usual locations"
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché zCustom.SnapBackup.sh"
checkfieldquit TrakBuild,GoLive $STAGE
checkfieldquit database,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

