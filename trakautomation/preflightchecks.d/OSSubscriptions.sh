#!/bin/sh -e
# Checks that the system is registered/subscribed

. ./functions.sh


check_SLES() {
	cdcount=`zypper ls -d | tail -n +3 | cut -d'|' -f8 | awk '{print $1}' | grep ^cd:/// | wc -l`
	noncdcount=`zypper ls -d | tail -n +3 | cut -d'|' -f8 | awk '{print $1}' | grep -v ^cd:/// | wc -l`
	if [ -z "$cdcount" -o -z "$noncdcount" ]; then
		echo "=CRITICAL - Can't determine subscription status. Is somehting wrong?"
	elif [ $cdcount -eq 0 -a $noncdcount -eq 0 ]; then
		echo "=CRITICAL - got neither a CD repo or a subscribed online repo"
	elif [ $cdcount -ge 1 -a $noncdcount -eq 0 ]; then
		echo "=ALERT - got a CD repo, but no subscribed online repo"
	elif [ $noncdcount -eq 0 ]; then
		echo "=ALERT - no subscribed online repo"
	else
		# TODO
		echo "=NOTE - checks on other repos not implemented yet FIXME"
	fi
}
check_RHEL() {
	# TODO possibly do "subscriptino-manager identity" to find if system has:
	# Current identity is: <uuid>
	# name: <fqdn>
	# org name: <number>
	# org id: <hex>
	status=`subscription-manager list | grep '^Status:' | sed 's/^Status:\s*//' | sed 's/\s*$//'`
	expires=`LC_TIME=C subscription-manager list | grep '^\(Expires\|Ends\):' | awk '{print $2}'`
	if [ -z "$status" ]; then
		echo "=CRITICAL - Can't determine subscription status. Is somehting wrong? (1)"
	elif [ "$status" == 'Not Subscribed' ]; then
		echo "=CRITICAL - System is not subscribed"
	elif [ -z "$expires" ]; then
		echo "=CRITICAL - Can't determine subscription expiry. Is somehting wrong? (2)"
	else
#		isoexpires=`echo $expires | awk 'BEGIN {FS="/";OFS="-"} ; { print $3,$2,$1 }'`
		epoc=`date +%s`
#		expiresepoc=`date -d $isoexpires +%s`
		expiresepoc=`date -d $expires +%s`
		sectogo=$(($expiresepoc-$epoc))
		daystogo=$(($sectogo/86400))
		if [ $daystogo -lt 30 ]; then
			echo "=CRITICAL - Subscription has $daystogo days left"
		elif [ $daystogo -lt 60 ]; then
			echo "=ALERT - Subscription has $daystogo days left"
		elif [ $daystogo -lt 120 ]; then
			echo "=NOTE - Subscription has $daystogo days left"
		else
			echo "=OK - Subscription has $daystogo days left"
		fi
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - System is Registered/Subscribed"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

