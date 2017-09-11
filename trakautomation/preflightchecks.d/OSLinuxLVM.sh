#!/bin/sh -e
# Checks filesystems except /boot are using LVM2

. ./functions.sh


process_mounts() {
	dmmajor=`grep ' device-mapper$' /proc/devices | sed 's/^ \+//' | cut -d' ' -f1`
	dmmajor=`echo $dmmajor | sed 's/ /,/g'`
	sdmajor=`grep ' sd$' /proc/devices | sed 's/^ \+//' | cut -d' ' -f1`
	sdmajor=`echo $sdmajor | sed 's/ /,/g'`
	if [ -z "$dmmajor" -o -z "$sdmajor" ]; then
		echo "=CRITICAL - can't find device major numbers for device-mapper and/or sd"
		return
	fi
	while read mount; do
		mountpoint=`echo "$mount" | cut -d' ' -f2`
		device=`echo "$mount" | cut -d' ' -f1`
		devmajor=`ls -lH $device | awk '{print $5}' | cut -d, -f1`
		if [ -z "$mountpoint" -o -z "$device" -o -z "$devmajor" ]; then
			echo "=CRITICAL - can't determine mountpoint, device or device major number for \"$device\""
			continue
		fi
		case $mountpoint in
			/boot|/boot/)
				bootfound=$device
				if listunion $devmajor $sdmajor; then
					echo "=OK - $mountpoint is on a \"sd\" device"
				else
					echo "=ALERT - $mountpoint is not on a \"sd\" device"
				fi
			;;
			*)
				if listunion $devmajor $dmmajor; then
					echo "=OK - $mountpoint is on a \"device-mapper\" device"
				else
					echo "=ALERT - $mountpoint is not on a \"device-mapper\" device"
				fi
			;;
		esac
	done
	if [ -z "$bootfound" ]; then
		echo "=ALERT - no /boot/ mountpoint and/or device found"
	fi
}



check_LINUX() {
	grep ^/dev/ /proc/mounts | awk '{print $1,$2}' | process_mounts
}

check_UNIX() {
	echo "=SKIP - would be active for Linux"
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Linux LVM Use"
#checkfieldquit CacheBuild $STAGE	# Always
#checkfieldquit database,app,print $FUNCTIONS	# Always
# would have bailed above if no match
osspecific check

