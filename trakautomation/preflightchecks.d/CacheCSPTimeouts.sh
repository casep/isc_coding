#!/bin/sh -e
# Checks for Server_Response_Timeout=900 and Queued_Request_Timeout=900 in [SYSTEM] section of CSP.ini

. ./functions.sh


check_LINUX() {
	set +e
	srTimeout=`ini_getparam.pl /opt/cspgateway/bin/CSP.ini SYSTEM Server_Response_Timeout 2>/dev/null`
	qrTimeout=`ini_getparam.pl /opt/cspgateway/bin/CSP.ini SYSTEM Queued_Request_Timeout 2>/dev/null`
	set -e
	if [ -z "$srTimeout" -o -z "$qrTimeout" ]; then
		echo "=ALERT - Expected [SYSTEM]->Server_Response_Timeout and/or [SYSTEM]->Queued_Request_Timeout config NOT found (potentially fragile)"
	else
		if [ $srTimeout -lt 900 ]; then
			echo "=ALERT - [SYSTEM]->Server_Response_Timeout=$srTimeout where 900 expected"
		elif [ $srTimeout -gt 900 ]; then
			echo "=NOTE - [SYSTEM]->Server_Response_Timeout=$srTimeout where 900 expected"
		else
			echo "=OK - Expected [SYSTEM]->Server_Response_Timeout=$srTimeout config found"
		fi
		if [ $qrTimeout -lt 900 ]; then
			echo "=ALERT - [SYSTEM]->Queued_Request_Timeout=$qrTimeout where 900 expected"
		elif [ $qrTimeout -gt 900 ]; then
			echo "=NOTE - [SYSTEM]->Queued_Request_Timeout=$qrTimeout where 900 expected"
		else
			echo "=OK - Expected [SYSTEM]->Queued_Request_Timeout=$qrTimeout config found"
		fi
	fi
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
echo "*CHECK - CSP Timeouts config"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit web,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

