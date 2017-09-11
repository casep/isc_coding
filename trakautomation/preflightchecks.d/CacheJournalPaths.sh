#!/bin/sh -e
# Checks Cache instances for Journals on same mountpoint and directory

. ./functions.sh


check_Unix() {
	# check through each instance
	for instance in `cache_getinstances.pl`; do
		path=`cache_instance2path.pl "$instance"`
		prijournal=`ini_getparam.pl $path/cache.cpf Journal CurrentDirectory`
		altjournal=`ini_getparam.pl $path/cache.cpf Journal AlternateDirectory`
		if [ -z "$prijournal" ]; then
			echo "=CRITICAL - instance \"$instance\" Journal CurrentDirectory missing"
		fi
		if [ -z "$altjournal" ]; then
			echo "=CRITICAL - instance \"$instance\" Journal AlternateDirectory missing"
		fi
		primountpoint=`getmountinfo.pl $prijournal | grep '^mount:' | cut -d: -f2-`
		altmountpoint=`getmountinfo.pl $altjournal | grep '^mount:' | cut -d: -f2-`
		if [ -z "$primountpoint" ]; then
			echo "=CRITICAL - instance \"$instance\" can't find mountpoint for Journal CurrentDirectory"
		fi
		if [ -z "$altmountpoint" ]; then
			echo "=CRITICAL - instance \"$instance\" can't find mountpoint for Journal AlternateDirectory"
		fi
		if [ "$prijournal" = "$altjournal" ]; then
			echo "=ALERT - instance \"$instance\" Journal locations are the same"
		elif [ "$primountpoint" = "$altmountpoint" ]; then
			# this is often expected with print and analytics servers as well as BASE / TRAIN / SCRATCH
# TODO this doesn't seem to work TODO
			if echo "$instance" | grep -q -e 'PRT[0-9]*$' -e 'ANALYTICS$'; then
				echo "=NOTE - instance \"$instance\" Journal locations are the same mountpoint, expected for this function"
# TODO this is based on the $ENV, not the particular instance TODO
			elif echo "$ENV" | grep -q -e '^BASE' -e '^TRAIN' -e '^SCRATCH'; then
				echo "=NOTE - instance \"$instance\" Journal locations are the same mountpoint, expected for this environment"
			else
				echo "=ALERT - instance \"$instance\" Journal locations are the same mountpoint"
			fi
		else
			echo "=OK - instance \"$instance\" Journal locations are sane"
		fi
	done
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché Journal Locations"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

