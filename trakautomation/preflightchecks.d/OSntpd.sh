#!/bin/sh -e
# Checks for common misconfiguration and good sync

. ./functions.sh


check_Unix() {
	CONF=/etc/ntp.conf
	if [ ! -f $CONF ]; then
		echo "=ALERT - No $CONF. Is ntpd installed?"
	elif grep -q '^server ' $CONF; then
		if grep -q '^server .\+\.ntp\.org' $CONF; then
			echo "=ALERT - Public NTP server configured. Sync may be poor. Should use secured local servers only."
		elif  grep -qv '^server \+127\.' $CONF && grep -q '^server ' $CONF; then
			# some non-local servers
			max=-1
# TODO on AIX there seems to be no symbol up front so the grep would prevent finding anything TODO
			for offset in `ntpq -pn | tail -n +3 | grep -v '^ ' | awk '{print $9}' | sed 's/^-//' | cut -d. -f1`; do
				if [ $offset -gt $max ]; then
					max=$offset
				fi
			done
			if [ $max -eq -1 ]; then
				echo "=CRITICAL - Can't get synced server - assume out of sync with NTP server(s)"
			elif [ $max -lt 250 ]; then
				echo "=OK - Appears to have an NTP server configred and has plausible sync (max offset ${max}ms)"
			elif [ $max -lt 1000 ]; then
				echo "=NOTE - Unusually high offset to NTP server (${max}ms) if in sync"
			elif [ $max -lt 4000 ]; then
				echo "=ALERT - Likely out of sync with NTP server(s) (offset ${max}ms)"
			else
				echo "=CRITICAL - Badly out of sync with NTP server(s) (offset ${max}ms)"
			fi
		else
			echo "=ALERT - Local (normally unsynced) NTP server configured"
		fi
	else
		echo "=ALERT - No NTP server configured"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - NTP Config"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS
# would have bailed above if no match
osspecific check

