#!/bin/sh -e
# Checks for authentication for Management & Connection to databases

. ./functions.sh


check_LINUX() {
	set +e
	username=`ini_getparam.pl /opt/cspgateway/bin/CSP.ini SYSTEM Username 2>/dev/null`
	password=`ini_getparam.pl /opt/cspgateway/bin/CSP.ini SYSTEM Password 2>/dev/null`
	set -e
	# check CSP Gateway Management
	if [ -z "$username" -o -z "$password" ]; then
		echo "=ALERT - no Username/Password for CSP Gateway Management"
	elif [ "$username" != 'CSPGwAdmin' ]; then
		echo "=NOTE - Found Username \"$username\" instead of usual \"CSPGwAdmin\" for CSP Gateway Management"
	else
		echo "=OK - Found Username & Password for CSP Gateway Management"
	fi
	# get databases (one connection each)
	for database in `ini_getsection.pl /opt/cspgateway/bin/CSP.ini SYSTEM_INDEX | cut -d= -f1`; do
		if [ $database == 'LOCAL' ]; then continue; fi
		username=`ini_getparam.pl /opt/cspgateway/bin/CSP.ini $database Username 2>/dev/null`
		password=`ini_getparam.pl /opt/cspgateway/bin/CSP.ini $database Password 2>/dev/null`
		if [ -z "$username" -o -z "$password" ]; then
			echo "=ALERT - no Username/Password for connection to database \"$database\""
		elif [ "$username" != 'CSPSystem' ]; then
			echo "=NOTE - Found Username \"$username\" instead of usual \"CSPSystem\" for database \"$database\""
		else
			echo "=OK - Found Username & Password for database \"$database\""
		fi
	done
}
check_AIX() {
	# behaves the same as Linux so just run that
	check_LINUX
}
check_Unix() {
	echo "=NOTE - check not done for platforms other than SUSE, Red Hat and AIX as no reports of problems (yet)"
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - CSP Authenticaiton is configured"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit web,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

