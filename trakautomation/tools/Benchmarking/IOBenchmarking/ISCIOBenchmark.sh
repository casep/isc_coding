#!/bin/sh
# Basic Storage benchmark (OS level) for Caché deployment
# Glen Pitt-Pladdy (InterSystems)
#
VERSION=20130716
# Set the target dd and iozone space usage:
ddsize=4096
iozonesize=16384
#ddsize=1024
#iozonesize=2048
# where to put stuff
workdir=ISCIOBenchmarkWorkDir
logdir=/tmp/ISCIOBenchmarkLogDir
# Set what modes we use
directIO=1
normalIO=0


# run OS specific function / callback
osspecific() {
	# fist arg is function prefix, rest are args
	if grep -q "^Red Hat Enterprise Linux Server release " /etc/issue; then
		COMMAND=$1_RHEL
	elif grep -q "^CentOS release " /etc/issue; then
		COMMAND=$1_CentOS
	elif grep -q "SUSE Linux Enterprise Server " /etc/issue; then
		COMMAND=$1_SLES
	elif grep -q "^Ubuntu " /etc/issue; then
		COMMAND=$1_Ubuntu
	elif grep -q "^Debian " /etc/issue; then
		COMMAND=$1_Debian
	else
		echo Dunno this OS >&2
		exit 1
	fi
	# clear off function arg ($1) and execute
	shift 1
	$COMMAND "$@"
	return $?
}

usage() {
#	echo "Usage: $0 <read test block device> [optional destrictive write block device]" >&2
	echo "Usage: $0 <read test block device>" >&2
	echo "Suggest to run this in a \"script\" within a \"screen\" session to capture data" >&2
	exit 1
}

iostatstart() {
	if [ $useiostat = 0 ]; then return 0; fi
	iostat -x 5 >$logdir/$1 &
	sleep 5
	currentiostat=$!
}
iostatfinish() {
	if [ $useiostat = 0 ]; then return 0; fi
	sleep 5
	kill $currentiostat
	sleep 1
	mv -i $logdir/* .
}

seeker_SLES() {
	$startdir/seeker-SLES11SP2_x64 $1
}
chk_seeker_SLES() {
	if [ -x $startdir/seeker-SLES11SP2_x64 ]; then return 0
	else return 1; fi
}
seeker_RHEL() {
	$startdir/seeker-RHEL5.x_x64 $1
}
chk_seeker_RHEL() {
	if [ -x $startdir/seeker-RHEL5.x_x64 ]; then return 0
	else return 1; fi
}
seeker_Ubuntu() {
	$startdir/seeker-Ubuntu10_amd64 $1
}
chk_seeker_Ubuntu() {
	if [ -x $startdir/seeker-Ubuntu10_amd64 ]; then return 0
	else return 1; fi
}
seeker_Debian() {
	$startdir/seeker-Debian6_amd64 $1
}
chk_seeker_Debian() {
	if [ -x $startdir/seeker-Debian6_amd64 ]; then return 0
	else return 1; fi
}

iozone_SLES() {
	$startdir/iozone3_397_iozone-SLES11SP2_x64 $@
}
chk_iozone_SLES() {
	if [ -x $startdir/iozone3_397_iozone-SLES11SP2_x64 ]; then return 0
	else return 1; fi
}
iozone_RHEL() {
	$startdir/iozone3_397_iozone-RHEL5.x_x64 $@
}
chk_iozone_RHEL() {
	if [ -x $startdir/iozone3_397_iozone-RHEL5.x_x64 ]; then return 0
	else return 1; fi
}
iozone_Ubuntu() {
	iozone $@
}
chk_iozone_Ubuntu() {
	if [ -x `which iozone` ]; then return 0
	else return 1; fi
}
iozone_Debian() {
	iozone $@
}
chk_iozone_Debian() {
	if [ -x `which iozone` ]; then return 0
	else return 1; fi
}



#############################################################################
# main starts here
#############################################################################


# get our start dir
startdir=`pwd`
# and do sanity checks
if [ ! -x `which dd` ]; then
	echo "FATAL - can't find \"dd\"" >&2
	exit 1
elif [ ! -x `which hdparm` ]; then
	echo "FATAL - can't find \"hdparm\"" >&2
	exit 1
elif [ ! -x `which dc` ]; then
	echo "FATAL - can't find \"dc\"" >&2
	exit 1
elif ! osspecific chk_seeker; then
	echo "FATAL - can't find \"seeker\" (should be in thid dir)" >&2
	exit 1
elif ! osspecific chk_iozone; then
	echo "FATAL - can't find \"iozone\" (should be in thid dir)" >&2
	exit 1
fi
useiostat=1
if [ ! -x `which iostat` ]; then
	echo "WARNING - \"iostat\" not found - will continue without" >&2
	echo "Press return/enter to continue"
	read
	useiostat=0
fi
# work out free space, keeping 1GiB free
freespace=`df -m . | tail -n1 | sed 's/^.* \([0-9]\+\) \+[0-9]\+% .\+$/\1/'`
freespace=$((freespace-1024))
if [ $freespace -le $(($ddsize+$iozonesize)) ]; then
	echo "WARNING - insufficient free space (${freespace}MiB leaving 1GiB) for full test - reducing"
	scale=`dc -e "3 k $ddsize $iozonesize + $freespace / 1.1 * p"`
	ddsize=`dc -e "$ddsize $scale / p"`
	iozonesize=`dc -e "$iozonesize $scale / p"`
	echo "using ${ddsize}MiB for dd, ${iozonesize}MiB for iozone"
fi


# check args
if [ $# -lt 1 ]; then usage; fi
readblockdev=$1
if [ $# -ge 1 -a ! -b $1 ]; then usage; fi
destructive=0
if [ $# -ge 2 ]; then
	if [ ! -b $2 ]; then usage; fi
	echo "WARNING!"
	echo "This tool will perform write (destructive) tests on $2"
	conf=`hexdump -n4 -e '"%02x"' /dev/urandom`
	echo "To confirm type \"$conf\""
	read response
	if [ x$conf != x$response ]; then
		echo "doesn't match - aborting!"
		exit 1
	fi
	destructive=1
	writeblockdev=$1
	echo "WARNING - destructive benchmarking not implemented - aborting"
	exit 1
fi


# create a working directory
if !  mkdir $workdir; then
	echo "Current directory must be writable - aborting" >&2
	exit 1
fi
cd $workdir
# create a logging directory in /tmp
# this is needed to avoid IO contention stalling the logging during tests
if ! mkdir $logdir; then
	echo "Failed creating \"$logdir\" - aborting" >&2
	exit 1
fi



# collect mount info
mount >info--mount.log
cat /proc/mounts >info--proc_mounts.log
# collect LVM info
vgdisplay=`which vgdisplay 2>/dev/null`
if [ ! -z "$vgdisplay" -a -x $vgdisplay ]; then
	vgdisplay -v >info--vgdisplay.log 2>&1
fi
lvdisplay=`which lvdisplay 2>/dev/null`
if [ ! -z "$lvdisplay" -a -x $lvdisplay ]; then
	lvdisplay --maps >info--lvdisplay.log 2>&1
fi
# queue info for block devices
for blocksched in /sys/block/*/queue/scheduler; do
	echo -n "$blocksched = " >>info--blockdev_scheduler.log
	cat $blocksched >>info--blockdev_scheduler.log
done


# titles
echo "=================="
echo "InterSystems IO Benchmark Suite"
echo "Glen Pitt-Pladdy $VERSION"
echo
echo Started `date`
echo In `pwd`
echo


# run seeker (read-only) test
echo "=================="
echo "seeker test on $readblockdev"
date
iostatstart seeker.log
osspecific seeker $readblockdev
iostatfinish
echo
echo

# run basic dd write test
ddcount=$(($ddsize/8/2))
echo "=================="
if [ $normalIO = 1 ]; then
	echo "dd write test (count $ddcount)"
	date
	iostatstart dd_write.log
	dd if=/dev/zero of=dd_testfile bs=8k count=${ddcount}k
	echo "syncing..."
	time sync
	iostatfinish
	echo
	echo
fi
if [ $directIO = 1 ]; then
	echo "dd direct write test"
	date
	iostatstart dd_write_direct.log
	dd if=/dev/zero of=dd_direct_testfile bs=8k count=${ddcount}k oflag=direct
	echo "syncing..."
	time sync
	iostatfinish
	echo
	echo
fi

# run read-only 
echo "=================="
echo "read-only hdparm tests on $readblockdev"
date
for itteration in 1 2 3 4 5; do
#for itteration in 1; do
	if [ $normalIO = 1 ]; then
		echo "read timing $itteration"
		iostatstart hdparm_read_$itteration.log
		date
		hdparm -tT $readblockdev
		iostatfinish
		echo
		echo
	fi
	if [ $directIO = 1 ]; then
		echo "Direct read timing $itteration"
		iostatstart hdparm_direct_read_$itteration.log
		date
		hdparm -tT --direct $readblockdev
		iostatfinish
		echo
		echo
	fi
done


# universal iozone test - sane defaults
do_iozone() {
	# usage: do_iozone <threads>
	# size of $iozonesize (default 16384MiB) and dice that by threads
	size=$(($iozonesize/$1))
	echo "====="
	if [ $directIO = 1 ]; then
		echo "iozone $1 threads, ${size}MB files, 8k records, DirectIO, read/re-read, random-read/write"
		iostatstart iozone_t${1}_s${size}m_r8k_I_i12.log
		date
		osspecific iozone -T -t $1 -s ${size}m -r 8k -I -i0 -i1 -i2
		iostatfinish
		echo
		echo
	fi


	if [ $normalIO = 1 ]; then
		echo "iozone $1 threads, ${size}MB files, 8k records, read/re-read, random-read/write"
		iostatstart iozone_t${1}_s${size}m_r8k_-_i12.log
		date
		osspecific iozone -T -t $1 -s ${size}m -r 8k -i0 -i1 -i2
		iostatfinish
		echo
		echo
	fi
}
# run iozone tests - in an order that gives most useful info fastest
echo "=================="
for threads in 8 2 16 1 4 32; do
	do_iozone $threads
done

# run basic dd read test
echo "=================="
if [ $normalIO = 1 ]; then
	echo "dd read test"
	date
	iostatstart dd_read.log
	dd if=dd_testfile of=/dev/null bs=8k
	iostatfinish
	rm dd_testfile
	echo
	echo
fi
if [ $directIO = 1 ]; then
	echo "dd direct read test"
	date
	iostatstart dd_read_direct.log
	dd if=dd_direct_testfile of=/dev/null bs=8k iflag=direct
	iostatfinish
	rm dd_direct_testfile
	echo
	echo
fi



# clean up
cd $startdir
rmdir $logdir
echo "See $workdir/ for iostat logs"











