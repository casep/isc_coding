#!/bin/sh -e
# Checks Cache instances for Journals on same mountpoint and directory

. ./functions.sh




check_Unix() {
	# check through each instance
	for instance in `cache_getinstances.pl`; do
		path=`cache_instance2path.pl "$instance"`
		wijdir=`ini_getparam.pl $path/cache.cpf config wijdir`
		globalbuffers=`ini_getparam.pl $path/cache.cpf config globals | cut -d, -f 3`
		globalbuffers=$(($globalbuffers*1024))
		if [ -z "$wijdir" ]; then
			wijdir=$path/mgr
		fi
		if [ ! -d $wijdir ]; then
			echo "=CRITICAL - instance \"$instance\" WIJ Directory \"$wijdir\" missing"
			continue
		fi
		if [ ! -f $wijdir/CACHE.WIJ ]; then
			echo "=CRITICAL - instance \"$instance\" WIJ Directory \"$wijdir\" missing CACHE.WIJ"
			continue
		fi
		if [ $globalbuffers -lt 16384 ]; then
			echo "=CRITICAL - instance \"$instance\" Global Buffers < 16MiB which is suspiciously small"
			continue
		fi
		# get the total space for WIJ - all in KiB
		wijfree=`df -kP $wijdir | tail -n 1 | awk '{print $4}'`
		wijused=`ls -lk $wijdir/CACHE.WIJ | awk '{print $5}'`
		wijmax=$(($wijfree+$wijused))
		# margin 20%
		wijsafe=$(($wijmax/5))
		wijsafe=$(($wijmax+$wijsafe))
		# check WIJ is safe for this tuning
		if [ $wijsafe -lt $globalbuffers ]; then
			echo "=ALERT - instance \"$instance\" WIJ total space of $wijmax KiB +20% ($wijsafe KiB) < Global Buffers ($globalbuffers KiB)"
		else
			echo "=OK - instance \"$instance\" WIJ space sufficient (does not take into account shared mountpoints)"
		fi
	done
}



# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché WIJ Space Available vs Global Buffers"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

