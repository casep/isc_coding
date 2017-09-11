#!/bin/sh -e
# Checks filesystems used by Cache instances for mount optinos

. ./functions.sh


# takes a LV device as an arg and outputs the PV devices associated with the parent VG
linuxLVM2_LV2PV() {
	vg=`lvdisplay $1 | grep '^ *VG Name \+' | sed 's/^ *VG Name \+//'`
	vgdisplay -v $vg 2>/dev/null | grep '^ *PV Name \+' | sed 's/^ *PV Name \+//'
}

# check the device (or partition) is tuned correctly
linux_checkdevice() {
	if [ "${1##/dev/cciss}" != "$1" ]; then
		# HP SmartArray controller
		parentdev=`echo $device | sed 's/p[0-9]\+$//'`
		# check RAID type TODO
		if [ -b $parentdev ]; then
			raidconfig=`grep "^${parentdev##/dev/}:" /proc/driver/cciss/* | sed 's/^.\+[\t ]\(RAID [0-9]\+\)$/\1/' | sed 's/ \+//g'`
			case $raidconfig in
				RAID5) echo "=ALERT - \"$mountpoint\" on $parentdev is using $raidconfig which is not ideal for database performance" ;;
				RAID10) echo "=OK - \"$mountpoint\" on $parentdev is using $raidconfig which is sane" ;;
				RAID1) echo "=NOTE - \"$mountpoint\" on $parentdev is using $raidconfig which is unexpected but maybe for valid reason" ;;
				RAID0) echo "=CRITICAL - \"$mountpoint\" on $parentdev is using $raidconfig which is insane" ;;
				*) echo "=ALERT - \"$mountpoint\" on $parentdev is using $raidconfig which is unknown to the preflight checks FIXME!" ;;
			esac
		fi
	else
		# generic device (eg. /dev/sda1)
		parentdev=`echo $1 | sed 's/[0-9]\+$//'`
	fi
	if [ -b $parentdev ]; then
		devfile=`echo $parentdev | sed 's/^.*\///'`
		if [ "${1##/dev/cciss}" != "$1" ]; then
			# HP SmartArray controller
			scheduler=`cat /sys/block/cciss\!$devfile/queue/scheduler | sed 's/^.*\[//' | sed 's/\].*//'`
		else
			# generic
			scheduler=`cat /sys/block/$devfile/queue/scheduler | sed 's/^.*\[//' | sed 's/\].*//'`
		fi
		case $scheduler in
			noop) echo "=NOTE - \"$mountpoint\" on $parentdev is using scheduler \"$scheduler\" which is an unexpected but maybe for valid reason" ;;
			deadline) echo "=OK - \"$mountpoint\" on $parentdev is using scheduler \"$scheduler\" which is sane" ;;
			cfq) echo "=ALERT - \"$mountpoint\" on $parentdev is using scheduler \"$scheduler\" which is often not ideal with high levels of concurrency" ;;
			*) echo "=ALERT - \"$mountpoint\" on $parentdev is using scheduler \"$scheduler\" which is unknown to the preflight checks FIXME!" ;;
		esac
	else
		echo "=CRITICAL - can't identify parent device for partition \"$1\""
	fi
}




check_LINUX() {
	# filesystems TODO more types
	case $filesystem in
		ext4|btrfs|reiserfs)
			echo "=ALERT - \"$mountpoint\" is $filesystem which is not well proven for databases"
			;;
		ext2)
			echo "=ALERT - \"$mountpoint\" is $filesystem which is very old and lacks journaling"
			;;
		ext3,xfs,jfs)
			echo "=OK - \"$mountpoint\" is $filesystem which is sane"
			;;
		*)
			echo "=NOTE - \"$mountpoint\" is $filesystem which has no checking logic FIXME!"
			;;
	esac
	# device - check scheduler
	if [ "${device##/dev/mapper}" != "$device" ]; then
		# assuming LVM2 in use - run through all PV devices
		pvs=`linuxLVM2_LV2PV $device`
		for pv in $pvs; do
			echo "=NOTE - \"$mountpoint\" is using mapper (LVM?) so trying to check PV \"$pv\" of VG where LV is"
			linux_checkdevice $pv
		done
	else
		linux_checkdevice $device
	fi
	# check mount options
	stufffound=0
	if ! listunion noatime $options; then
		echo "=ALERT - \"$mountpoint\" options \"$options\" don't include \"noatime\""
		stufffound=1
	fi
	case $filesystem in
		ext3|ext4)
			if listunion 'barrier=1' $options; then
				echo "=NOTE - \"$mountpoint\" options \"$options\" using \"barrier=1\" which makes it safe on volatile disk caches, but if battery backed disk cache (non-volatile) is in use then \"barrier=0\" may be beneficial"
				stufffound=1
			fi
			;;
		xfs)
			if listunion 'barrier' $options; then
				echo "=NOTE - \"$mountpoint\" options \"$options\" using \"barrier\" which makes it safe on volatile disk caches, but if battery backed disk cache (non-volatile) is in use then removing this may be beneficial"
				stufffound=1
			fi
			;;
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO 
		vxfs)
# vxfs
echo "NOT IMPLEMENTED YET"
# depends on $function
			case $function in
				database|journal)
					# As per "AIX Platform Notes" and "UNIX File System Recommendations"
					if ! listunion 'cio' $options; then
						echo "=ALERT - \"$mountpoint\" not mounted \"cio\" which could impact performance, but ensure other things are not on this same filesystem if \"cio\" is to be used"
						stufffound=1
					fi
					;;
				wij)
echo "NOT IMPLEMENTED YET"
					;;
			esac
			;;
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO 
		*)
			echo "=NOTE - \"$mountpoint\" options \"$options\" has no checking logic for $filesystem FIXME!"
			;;
	esac
	if [ $stufffound -eq 0 ]; then
		echo "=OK - \"$mountpoint\" options \"$options\" sane"
	fi
}
check_AIX() {
	# filesystems TODO more types
	case $filesystem in
		jfs2|vxfs)
			echo "=OK - \"$mountpoint\" is $filesystem which is sane"
			;;
		*)
			echo "=NOTE - \"$mountpoint\" is $filesystem which has no checking logic FIXME!"
			;;
	esac
	# device - check scheduler TODO
#	if [ "${device##/dev/mapper}" != "$device" ]; then
#		# assuming LVM2 in use - run through all PV devices
#		pvs=`linuxLVM2_LV2PV $device`
#		for pv in $pvs; do
#			echo "=NOTE - \"$mountpoint\" is using mapper (LVM?) so trying to check PV \"$pv\" of VG where LV is"
#			linux_checkdevice $pv
#		done
#	else
#		AIX_checkdevice $device
#	fi
	# check mount options
	stufffound=0
#	if ! listunion noatime $options; then
#		echo "=ALERT - \"$mountpoint\" options \"$options\" don't include \"noatime\""
#		stufffound=1
#	fi
	case $filesystem in
		jfs2)
			case $function in
				database|journal)
					# As per "AIX Platform Notes" and "UNIX File System Recommendations"
					if ! listunion 'cio' $options; then
						echo "=ALERT - \"$mountpoint\" not mounted \"cio\" which could impact performance, but ensure other things are not on this same filesystem if \"cio\" is to be used"
						stufffound=1
					fi
					;;
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO 
				wij)
					# As per "AIX Platform Notes"
					if ! listunion 'rw' $options; then
						echo "=ALERT - \"$mountpoint\" not mounted \"rw\" which could impact performance, but ensure other things are not on this same filesystem if \"cio\" is to be used"
						stufffound=1
					fi
					;;
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO 
			esac
			;;
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO 
		vxfs)
# vxfs
echo "NOT IMPLEMENTED YET"
			case $function in
				database|journal)
					# As per "AIX Platform Notes" and "UNIX File System Recommendations"
					if ! listunion 'cio' $options; then
						echo "=ALERT - \"$mountpoint\" not mounted \"cio\" which could impact performance, but ensure other things are not on this same filesystem if \"cio\" is to be used"
						stufffound=1
					fi
					;;
				wij)
echo "NOT IMPLEMENTED YET"
					;;
			esac
			;;
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO 
		*)
			echo "=NOTE - \"$mountpoint\" options \"$options\" has no checking logic for $filesystem FIXME!"
			;;
	esac
	if [ $stufffound -eq 0 ]; then
		echo "=OK - \"$mountpoint\" options \"$options\" sane"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Caché mountpoint tuning"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
# check through each instance
for instance in `cache_getinstances.pl`; do
	path=`cache_instance2path.pl "$instance"`
	databases=`ini_getsection.pl $path/cache.cpf Databases | tail -n +2 | grep -v '^[^,]*,[^,]' | cut -d= -f2 | cut -d, -f1 | sort`
	journalpri=`ini_getparam.pl $path/cache.cpf Journal CurrentDirectory`
	journalsec=`ini_getparam.pl $path/cache.cpf Journal AlternateDirectory`
	wijdir=`ini_getparam.pl $path/cache.cpf config wijdir`
	if [ -z "$wijdir" ];  then wijdir=$path/mgr/; fi
	# check through each database
	for database in $wijdir $journalpri $journalsec $databases; do
		if [ -z "$database" ]; then continue; fi
		# figure out function (may be used later)
		case $database in
			$wijdir)
				function=wij
			;;
			$journalpri|$journalsec)
				function=journal
			;;
			*)
				# anything else must be a database
				function=database
			;;
		esac
		# trim trailing / and identify mountpoint
		database=`echo $database | sed 's/\(.\)\/$/\1/'`
		mountpoint=`getmountinfo.pl "$database" | grep '^mount:' | cut -d: -f2-`
		# try to skip duplicates TODO this resquires the list to be sorted... not possible currently
		if [ "$mountpoint" = "$lastmountinfo" ]; then continue; fi
		lastmountinfo="$mountpoint"
		# extract the fields
		device=`getmountinfo.pl "$database" | grep '^device:' | cut -d: -f2-`
		filesystem=`getmountinfo.pl "$database" | grep '^filesystem:' | cut -d: -f2-`
		options=`getmountinfo.pl "$database" | grep '^options:' | cut -d: -f2-`
		# OS specific checks on this
		osspecific check
	done
done



