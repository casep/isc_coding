#!/bin/sh -e
# Checks main Trak database has a CF("SM") mapping which has previously been missed in global mappings

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
		# get & check CF("SM") mapping
		set +e
		mapping=`ini_getparam.pl $conf "Map.$namespace" 'Global_CF("SM")' 2>/dev/null`
		set -e
		if [ -z "$mapping" ]; then
			echo "=ALERT - No ^CF(\"SM\") mapping found for namespace \"$namespace\" in \"$conf\""
		elif [ "$mapping" = "$namespace-SYSCONFIG" ]; then
			echo "=OK - Found ^CF(\"SM\") mapping for namespace \"$namespace\" in \"$conf\""
		else
			echo "=ALERT - Found ^CF(\"SM\") invalid mapping for namespace \"$namespace\" in \"$conf\""
		fi
		# get & check CF global mapping
		set +e
		mapping=`ini_getparam.pl $conf "Map.$namespace" 'Global_CF' 2>/dev/null`
		set -e
		if [ -z "$mapping" ]; then
			echo "=ALERT - No ^CF mapping found for namespace \"$namespace\" in \"$conf\""
		elif [ "$mapping" = "$namespace-DATA" ]; then
			echo "=OK - Found ^CF valid mapping for namespace \"$namespace\" in \"$conf\""
		else
			echo "=ALERT - Found ^CF invalid mapping for namespace \"$namespace\" in \"$conf\""
		fi
		# get & check CF* global mapping
		set +e
		mapping=`ini_getparam.pl $conf "Map.$namespace" 'Global_CF*' 2>/dev/null`
		set -e
		if [ -z "$mapping" ]; then
			echo "=OK - No ^CF* mapping found for namespace \"$namespace\" in \"$conf\""
		else
			echo "=ALERT - Found ^CF* mapping (should be none) for namespace \"$namespace\" in \"$conf\""
		fi
	done
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare CF/CF(\"SM\")/CF mapping"
checkfieldquit TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview $FUNCTIONS
# would have bailed above if no match
osspecific check

