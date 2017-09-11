# ========================================================================
# Note that InterSystems provides this script / library to assist with
# backups of a TrakCare system and does not support this script nor
# include it in # the SLA. It is provided as a basis that sites may use
# as an example or extend it as required.
# ========================================================================


CALLIN=`dirname $0`/zCustom.SnapBackup.sh

# set default exit status
EXITFAILURE=1
EXITSUCCESS=0

# SuSE 11SP2 LVM2 (and possibly others) don't remove snapshots cleanly
WORKAROUNDLVM=1

# Warning level in % for LVM usage on remove
LVMWARNINGLEVEL=30
# Return 1 (failure) if this level is exceeded (ie. draw attention to the problem)
LVMWARNINGFAIL=0


MOUNTPOINT=/backup

# generic heading printing
heading() {
	echo "$1" | sed 's/./=/g'
	echo "$1"
	echo "$1" | sed 's/./=/g'
}
# creates directory path and mounts the device
makemount() {
	device="$1"
	mountpoint="$2"
	shift 2
	[ -d "$mountpoint" ] || mkdir -p "$mountpoint"
	echo mount "$device" "$mountpoint" "$@"
	mount "$device" "$mountpoint" "$@"
}
# unmount all nodes below a given directory
umountall() {
	local dir=`echo $1 | sed 's/\/$//'`
	if [ ! -d "$dir" ]; then
		return 1
	fi
	local backuperror=0
	cut -d' ' -f2 </proc/mounts | grep -e ^$MOUNTPOINT/ -e ^$MOUNTPOINT$ | sort -r \
		| while read line; do
			echo "umount \"$line\""
			umount "$line" || backuperror=$?
		done
	return $backuperror
}
# check if things are mounted below a given directory (ie. snapshots active)
# returns the number of things mounted
ismounted() {
	local dir=`echo $1 | sed 's/\/$//'`
	if [ ! -d "$dir" ]; then
		return 1
	fi
	return `cut -d' ' -f2 </proc/mounts | grep -e ^$MOUNTPOINT/ -e ^$MOUNTPOINT$ | wc -l`
}
# safely remove logical volume (works round problems on some distros)
# Args: <mapperdev>
linuxlvremovesafe() {
	count=0
	# extract vg, lv and standardise device to the /dev/mapper/ path
	if echo "$1" | grep -q ^/dev/mapper/; then
		vg=`echo $1 | sed 's/^.*\/\([^-\/]\+\)-[^-\/][^\/]\+$/\1/' | sed 's/--/-/g'`
		lv=`echo $1 | sed 's/^.*[^-]-\([^-].*\)$/\1/' | sed 's/--/-/g'`
		dev=$1
	else
		vg=`echo $1 | sed 's/^\/dev\/\([^\/]\+\)\/.*$/\1/'`
		lv=`echo $1 | sed 's/^\/dev\/[^\/]\+\/\([^\/]\+\)$/\1/'`
		dev=/dev/mapper/`echo $vg | sed 's/-/--/g'`-`echo $lv | sed 's/-/--/g'`
	fi
	# verify this LV exists
	lvdisplay $dev >/dev/null
	if [ $? -ne 0 ]; then
		echo "$dev Not found"
		return 1
	fi
	lvinactive=`lvdisplay $dev | grep 'LV snapshot status' | grep INACTIVE`
	# report the amount of space remaining
	lvusage=`lvdisplay $dev | grep 'Allocated to snapshot' | sed 's/\..*% *$//' | sed 's/^.* //'`
	# remove the lv
	if [ -n "$WORKAROUNDLVM" -a "$WORKAROUNDLVM" = 1 -a -e "$dev" ]; then
		echo "dmsetup remove $dev"
		dmsetup remove "$dev"
		sleep 1
	fi
	echo "lvremove --force $dev"
	while ! lvremove --force $dev; do
		count=$(($count+1))
		if [ $count -ge 3 ]; then
			echo -e "\t* aborting after $count tries"
			return 1
		fi
		echo -e "\t* Failed - retrying"
		sleep 1
	done
	if [ $count -gt 0 ]; then
		echo -e "\t* Success after $count tries"
	fi
	sleep 1
	if [ -n "$WORKAROUNDLVM" -a "$WORKAROUNDLVM" = 1 -a -e "$dev-cow" ]; then
		echo "dmsetup remove $dev-cow"
		dmsetup remove "$dev-cow"
		sleep 1
	fi
	# report if snapshot is inactive (probably exceeded space)
	if [ -n "$lvinactive" ]; then
		echo "ERROR - $dev INACTIVE (likely exceeded space available)"
		return 1
	fi
	# report snapshot usage if larger than expected
	if [ $lvusage -ge $LVMWARNINGLEVEL ]; then
		echo "WARNING - $lvusage% of this snapshot was used which leaves insufficient margin"
		# if the script should fail based on this (ie. to draw attention to the situation)
		if [ $LVMWARNINGFAIL != 0 ]; then
			return 1
		fi
	fi
}

exitwithstatus() {
	if [ $1 -eq 0 ]; then
		echo "* $1 Complete"
		exit $EXITSUCCESS
	else
		echo "* $1 Complete with ERRORS - see above"
		exit $EXITFAILURE
	fi
}

