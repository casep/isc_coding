#!/bin/sh -e
# Checks that key directories are on their own volumes
# Glen Pitt-Pladdy (ISC)
. ./functions.sh

echo "########################################"
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
	echo "Usage: $0 <Org Code> <Environment> <Version> [.... list of environment mountpoints to check]" >&2
	exit 1
fi

ret=0
checkmount () {
	# check it even exists
	if [ ! -d $1 ]; then
		echo "FATAL - Directory \"$1\" does not exist" >&2
		return 1
	fi
	# see if we can find it in the mounts
	for mount in `cut -d' ' -f2 </proc/mounts`; do
		if [ $mount = $1 ]; then
			# found it
			return 0
		fi
	done
	echo "FATAL - \"$1\" is not a mountpoint" >&2
	return 1
}

checknfsmount() {
	while read line; do
		mount=`echo $line | cut -d' ' -f2`
		nfssource=
		nfstype=
		if [ $mount = $1 ]; then
			nfssource=`echo $line | cut -d' ' -f1`
			nfstype=`echo $line | cut -d' ' -f3`
			break
		fi
	done </proc/mounts
	if [ -z "$nfssource" -o -z "$nfstype" ]; then
		echo "FATAL - can't find neccessary details for $1"
		return 1
	fi
	if [ $nfstype != "nfs" -a $nfstype != "nfs4" ]; then
		echo "FATAL - can't find expected NFS type for $1"
		return 1
	fi
	if ! echo "$nfssource" | grep -q :; then
		echo "FATAL - source doesn't appear to be NFS for $1"
		return 1
	fi

}

ORG=$1
ENVIRONMENT=$2
VER=$3
TRAKPATH=`trakpath $ORG $ENVIRONMENT DB$VER`
shift 3
# run through remaining arguments (mountpoints
for mountpoint in $@; do
	mountpointclean=`echo "$mountpoint" | cut -d: -f1`
	if echo "$mountpoint" | grep -q :; then
		mountpointtype=`echo "$mountpoint" | cut -d: -f2`
	else
		mountpointtype=default
	fi
	checkmount ${TRAKPATH}/$mountpointclean || exit $?
	case "$mountpointtype" in
		NFS)
			checknfsmount ${TRAKPATH}/$mountpointclean || exit $?
		;;
		'default')
		;;
		*)
			echo "FATAL - Type for \"$mountpointclean\" of \"$mountpointtype\" unknown"
			exit 1
		;;
	esac
done
