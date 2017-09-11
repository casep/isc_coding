#!/bin/sh -e
# Checks filesystems of any databases in Cache instances for usage

. ./functions.sh



check_LINUX() {
	foundbad=0
	for dfstat in `df | grep ' [0-9]\+% \+/[^ ]*$' | sed 's/^.* \([0-9]\+%\) \+\(\/[^ ]*\)$/\1=\2/'`; do
		usage=`echo $dfstat | cut -d% -f1`
		mountpoint=`echo $dfstat | cut -d= -f2`
		if [ $usage -ge 90 ]; then
			echo "=CRITICAL - Mountpoint \"$mountpoint\" has $usage% used"
			foundbad=1
		elif [ $usage -ge 75 ]; then
			echo "=ALERT - Mountpoint \"$mountpoint\" has $usage% used. That doesn't give much space for long-term growth."
			foundbad=1
		fi
	done
	if [ $foundbad -eq 0 ]; then
		echo "=OK - All mountpoints below 75% usage"
	fi
	# check inodes
	foundbad=0
	for dfstat in `df -i | grep ' [0-9]\+% \+/[^ ]*$' | sed 's/^.* \([0-9]\+%\) \+\(\/[^ ]*\)$/\1=\2/'`; do
		usage=`echo $dfstat | cut -d% -f1`
		mountpoint=`echo $dfstat | cut -d= -f2`
		if [ $usage -ge 60 ]; then
			echo "=CRITICAL - Mountpoint \"$mountpoint\" has $usage% inodes used"
			foundbad=1
		elif [ $usage -ge 40 ]; then
			echo "=ALERT - Mountpoint \"$mountpoint\" has $usage% inodes used. That doesn't give much space for long-term growth."
			foundbad=1
		fi
	done
	if [ $foundbad -eq 0 ]; then
		echo "=OK - All mountpoints below 40% inode usage"
	fi

}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Mountpoint usage"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,print,web $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific check

