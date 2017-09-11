#!/bin/sh -e
# Post build - Checks for HugePages configuration

. ./functions.sh


check_LINUX () {
	# collect info
	memtotal=`grep '^MemTotal: .\+ kB$' /proc/meminfo | sed 's/^.* \([0-9]\+\) .*$/\1/'`
	hugepagesize=`grep '^Hugepagesize: .\+ kB$' /proc/meminfo | sed 's/^.* \([0-9]\+\) .*$/\1/'`
	hugepages=`grep '^HugePages_Total: .\+$' /proc/meminfo | sed 's/^.* \([0-9]\+\)$/\1/'`
	if [ -z "$memtotal" ]; then
		echo "=CRITICAL - no System MemTotal found in /proc/meminfo. Is somehting wrong?"
		return
	fi
	if [ -z "$hugepagesize" -o -z "$hugepages" ]; then
		echo "=CRITICAL - no System Hugepagesize/HugePages_Total found in /proc/meminfo. Is somehting wrong?"
		return
	fi
	# work out total and thresholds per application
	hugepagestotal=$(($hugepagesize*$hugepages))
	min=$memtotal
#	max=0
	# work out maximum safe hugepages
	# the greater of leaving 1GiB free or half the system memory
	max=$(($memtotal-1048576))
	if [ $max -lt $(($memtotal/2)) ]; then
		max=$(($memtotal/2))
	fi
	# work out feasible minimum
	if listunion database $FUNCTIONS; then
		# database servers may contian multiple instances but may also leave execution of code to app servers
		expmin=$(($memtotal/3))
#		expmax=$((2*$memtotal/3))
		if [ $expmin -lt $min ]; then min=$expmin; fi
#		if [ $expmax -gt $max ]; then max=$expmax; fi
	fi
	if listunion app $FUNCTIONS; then
		# app servers need space to execute the code
		expmin=$(($memtotal/3))
#		expmax=$(($memtotal/2))
		if [ $expmin -lt $min ]; then min=$expmin; fi
#		if [ $expmax -gt $max ]; then max=$expmax; fi
	fi
	if listunion print $FUNCTIONS; then
		# print servers may need to run FOP with HugePages as well
		expmin=$(($memtotal/6))
#		expmax=$((3*$memtotal/4))
		if [ $expmin -lt $min ]; then min=$expmin; fi
#		if [ $expmax -gt $max ]; then max=$expmax; fi
	fi
	# check the thresholds
	if [ $hugepagestotal -lt $min ]; then
		echo "=ALERT - Only $hugepagestotal kB HugePages of $memtotal kB memory. That's likely not enough to do much useful (Post CacheBuild)."
	elif [ $hugepagestotal -gt $max ]; then
		echo "=ALERT - $hugepagestotal kB HugePages of $memtotal kB memory. That's likely to be too much and may affect other services."
	else
		echo "=OK - Found $hugepagestotal kB HugePages of $memtotal kB memory. That's likely a good balance (Post CacheBuild)."
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - HugePages (Post CacheBild)"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

