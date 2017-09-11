#!/bin/sh -e
# Checks Cache instances are set to auto-start under VM (HA) or ??XX (internal) environments

. ./functions.sh


check_Unix() {
	# get the relevant section of the /etc/init.d/isccache
	if [ ! -f /etc/init.d/isccache ]; then
		echo "=CRITICAL - can't find \"/etc/init.d/isccache\" so instances won't be auto-stopped at shutdown"
	else
		founderror=0
		autostarted=
		for inst in `GetSection.pl /etc/init.d/isccache '^startinst="' '"'`; do
			if [ -n "$autostarted" ]; then
				autostarted=$autostarted,$inst
			else
				autostarted=$inst
			fi
		done
		# check each instance
		eval `Platform2ENV.pl`
		for inst in `cache_getinstances.pl`; do
			# ignore integrity check instances which will normally be down
			if echo $inst | grep -q INTEGRITY$; then
				if listunion $autostarted $inst; then
					# should consider if we really want this to auto-start
					echo "=ALERT - instance \"$inst\" appears to be an Integrity check instance and should not Auto-Start"
					founderror=1
				fi
			elif echo $ENV | grep -qi ^..XX; then
				# should start
				if listunion $autostarted $inst; then
					echo "=ALERT - instance \"$inst\" is an ??XX (inernal) environment so expect it should Auto-Start"
					founderror=1
				fi
			else
				# check if start or not
				if listunion $autostarted $inst; then
					if [ -z '$PLATFORM_virtual' ]; then
						# should consider if we really want this to auto-start
						echo "=NOTE - instance \"$inst\" Auto-Starts but often better to manually start, especially if OS Clustering in use"
						founderror=1
					fi
				else
					if [ -n "$PLATFORM_virtual" ] && echo $PLATFORM_virtual | grep -q ^VMware; then
						# should check if HA requied
						echo "=ALERT - instance \"$inst\" should likely Auto-Start for VMware HA"
						founderror=1
					fi
				fi
			fi
		done
		if [ $founderror = 0 ]; then
			 echo "=OK - AutoStarting configuration seems sane"
		fi
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché Instances AutoStart"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

