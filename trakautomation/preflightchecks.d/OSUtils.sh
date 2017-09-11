#!/bin/sh -e
# Checks for utilities that are needed

. ./functions.sh


checkutils_Unix() {
	for util in $utils; do
		if type $util | grep -q ' is /[^ ]*$'; then
			echo "=OK - Utility \"$util\" found"
		else
			echo "=ALERT - Missing utility \"$util\""
		fi
	done
}


# OS Specific Utilities
extrautilsBase_LINUX() {
	echo top tar md5sum
}
extrautilsBase_AIX() {
	echo topas gtar md5sum
}
extrautilsBuild_LINUX() {
	echo tcpdump strace
}
extrautilsBuild_AIX() {
	echo 
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - System Utilities"
#checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
utils="host bc gzip bzip2 `osspecific extrautilsBase`"
case "$STAGE" in
	OSSkeleton|OSHandover)
		# nothing extra
		utils="$utils"
	;;
	CacheBuild|TrakUpgrade|TrakBuild|GoLive)
		utils="$utils iostat sar vmstat script screen telnet ftp wget w3m unzip `osspecific extrautilsBuild`"
	;;
	*)
		echo "Unknown Stage: $STAGE" >&2
		exit 1
	;;
esac
#checkfieldquit database,app,web,print $FUNCTIONS	# always run this
# would have bailed above if no match
osspecific checkutils $utils

