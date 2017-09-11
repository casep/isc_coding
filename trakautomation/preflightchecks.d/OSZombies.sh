#!/bin/sh -e
# Checks for sane ServerLimit, MaxClients and KeepAliveTimeout
# With inappropriate setting performancy may be poor to the point that service is lost

. ./functions.sh


check_LINUX () {
	zombies=`ps ax | sed 's/^.\{15\}\([^ ]\+\) .*$/\1/' | grep Z | wc -l`
	total=`ps ax | wc -l`
	percent=$((($zombies*100)/$total))
	if [ $zombies -eq 0 ]; then
		echo "=OK - No Zombies found"
	elif [ $percent -le 2 ]; then
		echo "=NOTE - Only $zombies Zombies found. That's only a problem if they hang around (or make weird noises)."
	elif [ $percent -ge 5 ]; then
		echo "=ALERT - $percent% of processes ($zombies / $total) are Zombies. That may be serious!"
	else
		echo "=ALERT - $zombies Zombies exist. That's more than would be expected on a healthy system."
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Zombie Processes"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

