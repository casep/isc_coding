#!/bin/sh -e
# Checks Cache instances for wdstrategy=1 being set (suits SANs better)

. ./functions.sh


check_Unix() {
	# check through each instance
	for instance in `cache_getinstances.pl`; do
		path=`cache_instance2path.pl "$instance"`
		set +e
		setting=`ini_getparam.pl $path/cache.cpf config wdstrategy 2>/dev/null`
		set -e
		if [ -z "$setting" ]; then
			echo "=ALERT - instance \"$instance\" can't find \"wdstrategy\" setting (2012 onwards)"
		elif [ $setting -eq 1 ]; then
			echo "=OK - instance \"$instance\" has \"wdstrategy\" set to \"1\" which should suit SAN storage"
		else
			echo "=ALERT - instance \"$instance\" has \"wdstrategy\" set to \"$setting\" which may not be optimum for SAN storage (2012 onwards)"
		fi
	done
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché \"wdstrategy\" is set"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
checkfieldquit 2012 $VER
# would have bailed above if no match
osspecific check

