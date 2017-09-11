#!/bin/sh -e
# Checks for optimum filesystem options for Perforce file storage

. ./functions.sh


check_LINUX () {
	DIR=`trakpath $SITE $ENV DB$VER`/perforce
	if [ ! -d $DIR ]; then
		echo "=NOTE - No mountpoint found for \"$DIR\". No further checks will be done."
		return 0
	fi
	while read line; do
		if [ `echo $line | cut -d' ' -f2` == $DIR ]; then
			break
		fi
	done </proc/mounts
	# check filesystem is ext*
	dev=`echo $line | cut -d' ' -f1`
	filesys=`echo $line | cut -d' ' -f3`
	if [ -z "$dev" ]; then
		echo "=ALERT - No mountpoint found for \"$DIR\""
		return 0
	fi
	case $filesys in
		ext2)
				echo "=ALERT- ext2 Filesystem not suitable (old, lacks optimisation features) on \"$DIR\""
		;;
		ext3|ext4)
			# example way of creating: mkfs.ext3 -L trak_perforce -b 1024 -i 1024 -O dir_index /dev/mapper/primary-trak_perforce
			# get info about ext* filesystems
			inodes=`tune2fs -l $dev | grep '^Inode count: ' | sed 's/^.* //'`
			blocks=`tune2fs -l $dev | grep '^Block count: ' | sed 's/^.* //'`
			blocksize=`tune2fs -l $dev | grep '^Block size: ' | sed 's/^.* //'`
			dirindex=`tune2fs -l $dev | grep '^Filesystem features: ' | grep dir_index`
			# looking for inodes == blocks && blocksize == 1024
			if [ -z "$inodes" -o -z "$blocks" -o -z "$blocksize" ]; then
				echo "=CRITICAL - Could not determine filesystem parameters for \"$DIR\""
				foundbad='yes'
			elif [ $inodes -eq $blocks -a $blocksize -le 1024 ]; then
				echo "=OK - Found inodes ($inodes) = blocks ($blocks) and Block Size = $blocksize for Perfroce Mountpoint \"$DIR\". That should be good for the small files."
			else
				if [ $inodes -lt $blocks ]; then
					echo "=ALERT - Found inodes ($inodes) < blocks ($blocks) for Perfroce Mountpoint \"$DIR\". With all the small files normally inodes = blocks is ideal."
					foundbad='yes'
				fi
				if [ $blocksize -gt 1024 ]; then
					echo "=ALERT - Found inodes ($inodes) < blocks ($blocks) for Perfroce Mountpoint \"$DIR\". With all the small files normally Block Size of 1024 is ideal."
					foundbad='yes'
				fi
			fi
			if [ ! -z "$dirindex" ]; then
				echo "=OK - Found Feature \"dir_index\" for Perfroce Mountpoint \"$DIR\". That should be good for the small files."
			else
				echo "=ALERT - Missing Feature \"dir_index\" for Perfroce Mountpoint \"$DIR\". That may impact performance for large numbers of small files."
				foundbad='yes'
			fi
			if [ -n "$foundbad" ]; then
				echo -n "=NOTE - Suitable filesystem may be careated with: "
				case $filesys in
					ext3)
						echo -n "mkfs.$filesys -L trak_perforce -b 1024 -i 1024 -O dir_index $dev"
					;;
					ext4)
						echo -n "mkfs.$filesys -L trak_perforce -b 1024 -i 1024 $dev"
					;;
					*)
						echo -n "Whoa! Filesystem not accounted for"
					;;
				esac
				echo -n " ... replacing \"trak_perforce\" with an appropriate label as needed"
			fi
		;;
		*)
			echo "=NOTE - Mountpoint \"$DIR\" using \"$filesys\" which is not currently checked. FIXME"
			return 0
		;;
	esac
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Perforce Filesystem parameters"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database $FUNCTIONS
checkfieldquit DR,RR $ENV
# would have bailed above if no match
osspecific check

