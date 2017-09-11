#!/bin/sh -e
# Checks Cache instances for Journal FreezeOnError being set (required for integrity)

. ./functions.sh


check_Unix() {
	# check through each instance
	for instance in `cache_getinstances.pl`; do
		path=`cache_instance2path.pl "$instance"`
		setting=`ini_getparam.pl $path/cache.cpf Monitor SNMPEnabled`
		if [ -z "$setting" ]; then
			echo "=CRITICAL - instance \"$instance\" Monitor SNMPEnabled setting missing"
		elif [ $setting -eq 1 ]; then
			echo "=OK - instance \"$instance\" Monitor SNMPEnabled=$setting which is sane"
		else
			echo "=ALERT - instance \"$instance\" Monitor SNMPEnabled=$setting which disables SNMP for this instance"
		fi
	done
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché SNMP is enabled"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

