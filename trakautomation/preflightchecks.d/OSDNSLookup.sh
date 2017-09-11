#!/bin/sh -e
# Checks for forward/reverse lookups for this host

. ./functions.sh


check_LINUX () {
	set +e
	# check hostname based on config
	hostname=`hostname | cut -d. -f1`
	fqdn=`hostname -f 2>/dev/null`
	# check hostname based lookups
	hostip=`host -t A $hostname | sed 's/^.* //'`
	[ -n "$fqdn" ] && fqdnip=`host -t A $fqdn | sed 's/^.* //'`
	set -e
	if echo "$hostip" | grep -q '\(SERVFAIL\|NXDOMAIN\)'; then
		echo "=ALERT - failed to get A record for host ($hostname)"
		error=1
	fi
	if echo "$fqdnip" | grep -q '\(SERVFAIL\|NXDOMAIN\)'; then
		echo "=ALERT - failed to get A record for FQDN ($fqdn)"
		error=1
	fi
	if [ -z "$error" ]; then
		if [ "$hostip" != "$fqdnip" ]; then
			echo "=ALERT - IPs for \"$hostname\" ($hostip) and \"$fqdn\" ($fqdnip) don't match"
			error=1
		fi
		set +e
		ip2hostcount=`host -t PTR $hostip | wc -l`
		ip2host=`host -t PTR $hostip | sed 's/^.* //' | sed 's/\.$//'`
		set -e
		if [ $ip2hostcount -gt 1 ]; then
			echo "=ALERT - more than one PTR record for ip ($hostip)"
			error=1
		elif echo "$ip2host" | grep '\(SERVFAIL\|NXDOMAIN\)'; then
			echo "=ALERT - failed to get PTR record for ip ($hostip)"
			error=1
		elif [ "$ip2host" != "$fqdn" ]; then
			echo "=ALERT - PTR record for this ip ($hostip) doesn't match FQDN ($ip2host != $fqdn)"
			error=1
		fi
	fi
	# check all forward lookups for this machine
	for ip in `ip addr show | grep "inet .* \(br\|bond\|eth\)[0-9]*$" | sed 's/^.* inet //' | cut -d' ' -f 1 | cut -d/ -f1`; do
		set +e
		ip2hostcount=`host -t PTR $ip | wc -l`
		ip2host=`host -t PTR $ip | sed 's/^.* //' | sed 's/\.$//'`
		set -e
		if [ $ip2hostcount -gt 1 ]; then
			echo "=ALERT - more than one PTR record for interface ip ($ip)"
			error=1
		elif echo "$ip2host" | grep -q '\(SERVFAIL\|NXDOMAIN\)'; then
			echo "=ALERT - failed to get PTR record for interface ip ($ip)"
			error=1
		elif [ "$ip2host" != "$fqdn" ]; then
			echo "=ALERT - PTR record for this interface ip ($ip) doesn't match FQDN ($ip2host != $fqdn)"
			error=1
		fi
	done
	# if no errors
	if [ -z "$error" ]; then
		echo "=OK - all DNS Lookup checks healthy"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - DNS Lookups"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

