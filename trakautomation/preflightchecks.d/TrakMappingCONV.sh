#!/bin/sh -e
# Checks main Trak database hase a CONV mapping to DATA which has previously been wrongly mapped from source

. ./functions.sh


check_Unix() {
	# itterate through all instances until we find a Trak one
	for instance in `cache_getinstances.pl`; do
		path=`cache_instance2path.pl "$instance"`
		conf="$path/cache.cpf"
		if [ ! -f "$conf" ]; then
			echo "=CRITICAL - can't find cache.cpf \"$conf\" for instance \"$instance\""
			continue
		fi
		if echo "$instance" | grep -q 'DB$'; then
			# main database
			namespace=`traknamespace $SITE $ENV`
		elif echo "$instance" | grep -q 'APP[0-9]*$'; then
			# App instance
			namespace=`traknamespace $SITE $ENV`
		elif echo "$instance" | grep -q 'PRT[0-9]*$'; then
			# Print instance
			namespace=EPS
		else
			continue;
		fi
		# check for the namespace
		nsconfig=`ini_getparam.pl $conf "Namespaces" "$namespace" 2>/dev/null`
		if [ -z "$nsconfig" ]; then
			echo "=ALERT - No Namespace \"$namespace\" in \"$conf\", not checking for mappings"
			continue
		fi
		# get & check mapping
		set +e
		mapping=`ini_getparam.pl $conf "Map.$namespace" Global_CONV 2>/dev/null`
		set -e
		if [ -z "$mapping" ]; then
			echo "=OK - No mapping found for Global_CONV (default to $namespace-DATA) for Namespace \"$namespace\" in \"$conf\""
		elif [ "$mapping" = "$namespace-DATA" ]; then
			echo "=OK - Found valid mapping for Global_CONV for Namespace \"$namespace\" in \"$conf\""
		else
			echo "=ALERT - Mapping for Global_CONV for Namespace \"$namespace\" in \"$conf\" should be to \"$namespace-DATA\" (records of the state of DATA should accompany data)"
		fi
	done
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare CONV mapping"
checkfieldquit TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview $FUNCTIONS
# would have bailed above if no match
osspecific check

