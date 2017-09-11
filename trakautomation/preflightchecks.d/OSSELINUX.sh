#!/bin/sh -e
# Checks for SELINUX is disabled
# With inappropriate setting performancy may be poor to the point that service is lost

. ./functions.sh


check_LINUX () {
	CONF=/etc/selinux/config
	ENFORCE=/selinux/enforce
	# check we have a line with some IP for this host TODO this could validatae the IP
	if [ ! -f $CONF ]; then
		echo "=OK - no \"$CONF\", assuming disabled"
	elif grep -q "^SELINUX=disabled$" $CONF; then
		echo "=OK - Appears to have \"disabled\" config"
	else
		echo "=ALERT - Can't find \"SELINUX=disabled\" in $CONF"
	fi
	if [ ! -f $ENFORCE ]; then
		echo "=OK - no \"$ENFORCE\", assuming disabled"
	elif [ `cat $ENFORCE` -eq 0 ]; then
		echo "=OK - Currently not enforcing SELINUX"
	else
		echo "=ALERT - Currently enforcing SELINUX"
	fi
}
check_UNIX() {
	echo "=SKIP - would be active for Linux"
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - SELINUX disabled"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

