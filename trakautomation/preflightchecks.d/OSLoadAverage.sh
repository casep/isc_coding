#!/bin/sh -e
# Checks Load Average

. ./functions.sh


check_Unix() {
	# work out thresholds
	eval `Platform2ENV.pl`
	# Generic limits that should be OK for Trak over LAN
	critical=$PLATFORM_cpus
	alert=`echo "scale=3; $critical / 2" | bc`
	if [ 0`echo "scale=3; if ( $alert < 1 ) 1" | bc` -eq 1 ]; then alert=1; fi
	note=1
	# work out averages
	loads=`uptime |  sed 's/^.*load average: //' | sed 's/, */ /g'`
	names='1 5 15'
	# run through each average
	count=1
	while [ $count -le 3 ]; do
		load=`echo $loads | cut -d' ' -f$count`
		name=`echo $names | cut -d' ' -f$count`
		count=$(($count+1))
		# check figures
		if [ 0`echo "scale=3; if ( $load >= $critical ) 1" | bc` -eq 1 ]; then
			echo "=CRITICAL - $name minute Load Average is $load (overloaded)"
		elif [ 0`echo "scale=3; if ( $load >= $alert ) 1" | bc` -eq 1 ]; then
			echo "=ALERT - $name minute Load Average is $load (high risk)"
		elif [ 0`echo "scale=3; if ( $load >= $note ) 1" | bc` -eq 1 ]; then
			echo "=NOTE - $name minute Load Average is $load (working hard)"
		else
			echo "=OK - $name minute Load Average is $load (safe)"
		fi
	done
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Load Average"
#checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS
# would have bailed above if no match
osspecific check

