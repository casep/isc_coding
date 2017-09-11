#!/bin/sh -e
# Checks Cache instances for License files and expiry dates

. ./functions.sh


check_Unix() {
	# check through each instance
	for instance in `cache_getinstances.pl`; do
		path=`cache_instance2path.pl "$instance"`
		if [ -f $path/mgr/cache.key ]; then
			expiressec=`cache_license2epoch.pl $path/mgr/cache.key`
			rel=$((($expiressec-`date +%s`)/86400))
			if [ $rel -ge 60 ]; then
				echo "=OK - instance \"$instance\" License expires in $rel days which is sane"
			elif [ $rel -le 0 ]; then
				echo "=CRITICAL - instance \"$instance\" License has expired!"
			else
				echo "=ALERT - instance \"$instance\" License expires in $rel days which is a risk"
			fi
			# check permissions
			perms=`ls -l $path/mgr/cache.key | awk '{print $1}'`
			if echo $perms | grep -q '^-r.-r.-.--'; then
				 echo "=OK - instance \"$instance\" License permissions are sane"
			else
				echo "=ALERT - instance \"$instance\" License permissions should at least allow user&group to read"
			fi
		else
			echo "=CRITICAL - instance \"$instance\" can't find License file \"$path/mgr/cache.key\""
		fi
	done
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché License files"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

