#!/bin/sh -e
# Checks for sane ServerLimit, MaxClients and KeepAliveTimeout
# With inappropriate setting performancy may be poor to the point that service is lost

. ./functions.sh


checkorder_RHEL() {
	pair=`grep "^[0-9a-fA-F\.:]\\+\\s" $CONF| grep -e "\\s$HOSTFQDN\\s" -e "\\s$HOSTFQDN$" | awk '{print $2,$3}'`
	if [ -z "$pair" ]; then
		echo "=CRITICAL - Can't find / parse entry for \"$HOSTFQDN\" in $CONF"
	elif [ "$pair" = "$HOST $HOSTFQDN" ]; then
		echo "=ALERT - $CONF entry in format IP-Hostname-FQDN which can confuse RH hostname command"
	elif [ "$pair" = "$HOSTFQDN $HOST" ]; then
		echo "=OK - Appears to have an entry for this host ($HOSTFQDN) which doesn't confuse RH hostname command"
	else
		echo "=CRITICAL - Unexpected scenario parsing entry for \"$HOSTFQDN\" in $CONF - possibly order IP-FQDN-Hostname which confuses RH hostname command"
	fi
}
checkorder_LINUX() {
	# don't do anything - order only seems to affect RHEL
	echo >/dev/null
}


check_LINUX () {
	CONF=/etc/hosts
	# There is some debate on hostnames - CentOS uses FQDN for everythign, RH is vague and non-comittal, Debian clearly separates hostname and FQDN
	# TODO RHEL (and presumably CentOS) is very sensitive to the order of /etc/hosts - should be: IP FQDN Hostname TODO
	# To be sure chop the domain part off
	set +e
	HOST=`hostname | sed 's/\..*$//'`
	# TODO AIX can't do "-f"
	HOSTFQDN=`hostname -f 2>/dev/null`
	set -e
	# check we have a line with some IP for this host TODO this could validatae the IP
	if [ -z "$HOSTFQDN" ]; then
		echo "=CRITICAL - Got invalid (empty) FQDN for is host"
	elif grep "^[0-9a-fA-F\.:]\\+\\s" $CONF| grep -q -e "\\s$HOSTFQDN\\s" -e "\\s$HOSTFQDN$"; then
		echo "=OK - Appears to have an entry for this host ($HOSTFQDN)"
#	elif grep "^[0-9a-fA-F\.:]\\+\\s" $CONF| grep -q "\\s$HOSTFQDN$"; then
#		echo "=OK - Appears to have an entry for this host ($HOSTFQDN)"
	else
		echo "=ALERT - No entry for this host ($HOSTFQDN) found"
	fi
	if [ -z "$HOST" ]; then
		echo "=CRITICAL - Got invalid (empty) Hostname for is host"
	elif grep "^[0-9a-fA-F\.:]\\+\\s" $CONF| grep -q -e "\\s$HOST\\s" -e "\\s$HOST$"; then
		echo "=OK - Appears to have an entry for this host ($HOST)"
#	elif grep "^[0-9a-fA-F\.:]\\+\\s" $CONF| grep -q "\\s$HOST$"; then
#		echo "=OK - Appears to have an entry for this host ($HOST)"
	else
		echo "=ALERT - No entry for this host ($HOST) found"
	fi
	osspecific checkorder
	if grep -q '^127\.0\.0\.1\s\+localhost\( .*\)\?$' $CONF; then
		echo "=OK - Appears to have an entry for localhost (127.0.0.1)"
	else
		echo "=ALERT - No entry for localhost found"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Valid /etc/hosts"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

