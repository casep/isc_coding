#!/bin/sh -e
# Checks for ping to CCR

. ./functions.sh


check_LINUX() {
	if ping -c3 -q ccr.intersystems.com >/dev/null; then
		if [ ! -x "`which wget 2>/dev/null`" ]; then
			echo "=CRITICAL - can't find \"wget\" to test access to \"ccr.intersystems.com\""
		else
			if wget --max-redirect=0 --no-check-certificate --timeout=10 --tries=3 --output-document=- http://ccr.intersystems.com/ 2>&1 | grep -q '^Location: https://ccr\.intersystems\.com/ccr/index\.csp'; then
				if wget --max-redirect=0 --no-check-certificate --timeout=10 --tries=3 --output-document=- http://ccr.intersystems.com/ 2>&1 | grep -q 'Location: https://ccr.intersystems.com/ccr/index\.csp'; then
					echo "=OK - Successful ping, http and https requests to \"ccr.intersystems.com\""
				else
					echo "=ALERT - Failed https request to \"ccr.intersystems.com\""
				fi
			else
				echo "=ALERT - Failed http request \"ccr.intersystems.com\""
			fi
		fi

	else
		echo "=ALERT - Failed ping \"ccr.intersystems.com\""
	fi
}
check_AIX() {
	if ping -c3 -q ccr.intersystems.com >/dev/null; then
		if [ ! -x "`which wget 2>/dev/null`" ]; then
			echo "=CRITICAL - can't find \"wget\" to test access to \"ccr.intersystems.com\""
		else
			if wget --timeout=10 --tries=3 --output-document=- http://ccr.intersystems.com/ 2>&1 | grep -q '^Location: https://ccr\.intersystems\.com/ccr/index\.csp'; then
				echo "=NOTE - Successful ping and http to \"ccr.intersystems.com\", but AIX wget is too limited to do more (eg. SSL)"
			else
				echo "=ALERT - Failed http request \"ccr.intersystems.com\""
			fi
		fi

	else
		echo "=ALERT - Failed ping \"ccr.intersystems.com\""
	fi
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Access to CCR"
#checkfieldquit OSSkeleton,OSHandover,CacheBuild $STAGE	# always run this
checkfieldquit database,app,print,preview,analytics $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

