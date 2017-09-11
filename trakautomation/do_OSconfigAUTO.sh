#!/bin/sh -e
# TODO Owing to the math for Cache not working, this is an attempt to do it automatically from the cconsole.log TODO
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


getmemlatest() {
	cconsole=$1
	latestmemory=0
	grep '\( (0) 2 Failed to allocate \| (0) [01] Allocated .* shared memory\|\\*\\*\\* Recovery started at \)' $cconsole | tail -n 20 \
		| while read line; do
echo "------$line" >&2
			if echo $line | grep -q '\\*\\*\\* Recovery started at '; then
				# new startup - reset
echo "New Startup" >&2
				latestmemory=0
			else
				# check for memory info in this line
				memory=0
				if echo $line | grep -q ' (0) 2 Failed to allocate '; then
					memory=`echo $line | sed 's/^.* 2 Failed to allocate \([0-9]\+\)MB shared memory.*$/\1/'`
				fi
				if echo $line | grep -q ' (0) [01] Allocated .* shared memory'; then
					memory=`echo $line | sed 's/^.* [01] Allocated \([0-9]\+\)MB shared memory.*$/\1/'`
				fi
				if [ $memory -eq 0 ]; then continue; fi
echo latest $latestmemory >&2
echo memory $memory >&2
				if [ $memory -gt $latestmemory ]; then
					latestmemory=$memory
				fi
echo latest $latestmemory >&2
				echo $latestmemory
			fi
	done | tail -n 1
}


check_LINUX() {
	SYSCTLCONF=/etc/sysctl.conf
#	LIMITSCONF=/etc/security/limits.conf
#	if [ -f ${SYSCTLCONF}.original -o -f ${LIMITSCONF}.original ]; then return 0; fi
	if [ -f ${SYSCTLCONF}.original ]; then return 0; fi
	return 1
}

# TODO RHEL has a /etc/security/limits.d/ and it would be neater to use that TODO but then we don't need to set that in recent distros
config_LINUX() {
	# find cache instances
	totalmemory=0
	for path in `ccontrol qlist | grep '\^\(running, since\|down,\)' | cut -d^ -f 2`; do
		# (0) 0 Allocated 206MB shared memory (huge pages): 116MB global buffers, 24MB routine buffers
		# (0) 0 Allocated 256MB shared memory: 128MB global buffers, 64MB routine buffers 
		# (0) 0 Allocated 390MB shared memory using Huge Pages: 256MB global buffers, 64MB routine buffers
		#
		# (0) 2 Failed to allocate 1375MB shared memory: 1200MB global buffers, 64MB routine buffers
		# (0) 2 Insufficient Huge Pages configured for required shared memory.
		# (0) 1 Allocated 1211MB shared memory: 1050MB global buffers, 56MB routine buffers

		# find last startup from each instance
		# accumulate the numbers
echo "Checking Instance log: $path/mgr/cconsole.log"
		latestmemory=`getmemlatest $path/mgr/cconsole.log`
		if [ -z "$latestmemory" ]; then latestmemory=0; fi
		if [ $latestmemory -eq 0 ]; then
			echo "FATAL - got instance memory 0 (bad parse of cconsole.log)" >&2
			return 1
		fi
echo total $totalmemory + $latestmemory
		totalmemory=$(($totalmemory+$latestmemory))
echo =total $totalmemory
	done
echo "All Caché total $totalmemory MiB"
	# sysctl.conf stuff
	# shmmax
	# from http://docs.intersystems.com/cache20111/csp/docbook/DocBook.UI.Page.cls?KEY=GCI_unixparms
	# get our totals in KB - originally had 4MiB margin, increased to 16MiB
	shmk=$(($totalmemory*1024+16384))
	# and in B
	shm=$(($shmk*1024))
	shmcurr=`cat /proc/sys/kernel/shmmax`
	# message quque
	# from http://iknow/sites/its/Product/Release%20Version%20Details/TrakCare%202012/06%20Technical/TrakCare%202012%20LINUX%20Install%20and%20Tuning%20Guide.docx
	msgmnireq=32768
	msgmaxreq=65536
	msgmnbreq=65536
	msgmnicur=`cat /proc/sys/kernel/msgmni`
	msgmaxcur=`cat /proc/sys/kernel/msgmax`
	msgmnbcur=`cat /proc/sys/kernel/msgmnb`
	# hugepages will be the same as SHM except in KiB
	# from http://docs.intersystems.com/cache20111/csp/docbook/DocBook.UI.Page.cls?KEY=GCI_unixparms
	hugepagesize=`grep ^Hugepagesize: /proc/meminfo | sed 's/^.*  \([0-9]*\) kB$/\1/'`
	# also check /etc/fop.conf and grab "-Xmx(\d+[gmk])" value as extra hugepages
	fopmemk=0
	if [ -f /etc/fop.conf ]; then
		memstr=`grep -e '-Xmx[0-9]\+[gmk]' /etc/fop.conf | sed 's/^.*-Xmx\([0-9]\+\)\([gmk]\).*$/\1 \2/'`
		if [ -z "$memstr" ]; then
			echo "FATAL - can't understand (or find) java -Xmx setting in /etc/fop.conf"
			exit 1
		fi
		fopmemk=`echo $memstr | cut -d' ' -f1`
		case `echo $memstr | cut -d' ' -f2` in
			g)
				fopmemk=$(($fopmemk*1024*1024))
			;;
			m)
				fopmemk=$(($fopmemk*1024))
			;;
			k)
				# no action needed
			;;
			*)
				echo "FATAL - can't understand java -Xmx setting - not one of [gmk] in /etc/fop.conf"
				exit 1
			;;
		esac
echo "FOP-HotJVM = $fopmemk k"
	fi
	# calculate total hugepages
	hugepagesk=$(($shmk+$fopmemk+$1))
	hugepagesreq=$(($hugepagesk/$hugepagesize+1))
# TODO for 4096 Global + 512 routine + 32M lockpages allocated 4994MB - that don't stack up: 386MB extra TODO
	# TODO semaphores (/proc/sys/kernel/sem) - no clear tuning guidance in TC docs
	# from http://docs.intersystems.com/cache20111/csp/docbook/DocBook.UI.Page.cls?KEY=GCI_unixparms
	# params are: SEMMSL, SEMMNS, SEMOPM, and SEMMNI
	# should be set:
	#	SEMMSL = max user processes (licenses) + 4 (as SEMMNI)
	#	SEMMNS = 128, or number of processes expected to run (including jobbed)
	#	SEMOPM = Oracle says >=100, but nothing from ISC
	#	SEMMNI = max user processes (licenses) + 4 (as SEMMSL)
	# also see "ipcs" command



	# backup config
	cp -a ${SYSCTLCONF} ${SYSCTLCONF}.original
	# general sysctl.conf setup
	# make our changes clear
	echo >>${SYSCTLCONF}
	echo '# InterSystems Added' >>${SYSCTLCONF}
	# set swappiness - generic
	echo 'vm.swappiness=5' >>${SYSCTLCONF}
	# Dirty Page Cleanup - no longer in T2014 docs
#	# from http://docs.intersystems.com/cache20111/csp/docbook/DocBook.UI.Page.cls?KEY=GCI_unixparms
#	echo 'vm.dirty_background_ratio=5' >>${SYSCTLCONF}
#	echo 'vm.dirty_ratio=10' >>${SYSCTLCONF}
	# shared memory - if arg is >0 ... else disable setting
	if [ $1 -ge 0 ]; then
		if [ $shmcur='18446744073709551615' ]; then
			echo "# Note - this is disabled as it was already found to be big enough" >>${SYSCTLCONF}
			echo -n "# " >>${SYSCTLCONF}
		elif [ $shmcur -ge $shm ]; then
			echo "# Note - this is disabled as it was already found to be big enough" >>${SYSCTLCONF}
			echo -n "# " >>${SYSCTLCONF}
		fi
		echo "kernel.shmmax=$shm" >>${SYSCTLCONF}
	fi
	# message queues
	if [ $msgmnicur -ge $msgmnireq ]; then
		echo "# Note - this is disabled as it was already found to be big enough" >>${SYSCTLCONF}
		echo -n "# " >>${SYSCTLCONF}
	fi
	echo "kernel.msgmni=$msgmnireq" >>${SYSCTLCONF}
	if [ $msgmaxcur -ge $msgmaxreq ]; then
		echo "# Note - this is disabled as it was already found to be big enough" >>${SYSCTLCONF}
		echo -n "# " >>${SYSCTLCONF}
	fi
	echo "kernel.msgmax=$msgmaxreq" >>${SYSCTLCONF}
	if [ $msgmnbcur -ge $msgmnbreq ]; then
		echo "# Note - this is disabled as it was already found to be big enough" >>${SYSCTLCONF}
		echo -n "# " >>${SYSCTLCONF}
	fi
	echo "kernel.msgmnb=$msgmnbreq" >>${SYSCTLCONF}
	# hugepages - if arg is >0 ... else disable setting
	if [ $1 -ge 0 ]; then
		if [ `cat /proc/sys/vm/nr_hugepages` -ge $hugepagesreq ]; then
			echo "# Note - this is disabled as it was already found to be big enough" >>${SYSCTLCONF}
			echo -n "# " >>${SYSCTLCONF}
		fi
		echo "vm.nr_hugepages=$hugepagesreq" >>${SYSCTLCONF}
	fi
	if [ $1 -lt 0 ]; then
		echo "# Note - shm* and HugePages disabled due to argument \"$1\"" >>${SYSCTLCONF}
	fi
	# set the new parameters active
	set +e
	sysctl -p ${SYSCTLCONF}
	sysctlret=$?
	set -e
	if [ $sysctlret -ne 0 ]; then
		echo
		echo "WARNING - sysctl returned $sysctlret"
		echo "This may be benign (eg. bad keys in existing config, but check before moving on"
		echo
		echo "Hit Return to continue / Ctrl-C to abort"
		read
	fi

#	# limits.conf stuff - TODO doesn't appear to be needed in modern linux - Huge Pages is memory locked anyway
#	# backup config
#	cp -a ${LIMITSCONF} ${LIMITSCONF}.original
#	# locked-in memory (+32kiB safety) TODO not sure this is neccessary TODO
#	# from http://docs.intersystems.com/cache20111/csp/docbook/DocBook.UI.Page.cls?KEY=GCI_unixparms
#	lockedink=$(($3/1024+32))
#	lockedinhardk=$(($lockedink/2+$lockedink))
#	echo >>${LIMITSCONF}
#	echo '# InterSystems Added' >>${LIMITSCONF}
#	echo "cachesys soft memlock $lockedink" >>${LIMITSCONF}
#	echo "cachesys hard memlock $lockedinhardk" >>${LIMITSCONF}
# TODO TODO TODO TODO TODO TODO
# need to set vm.hugetlb_shm_group = 2000 ($CACHEGRP) for E2010 to work at boot
# TODO TODO TODO TODO TODO TODO
}




echo "########################################"
# check args
if [ $# -ne 1 ]; then
	echo "Usage: $0 <aditional HugePages KiB>" >&2
	exit 1
fi


# go for it
if osspecific check; then
	echo "OS Configuration Exists"
	exit 0
else
	echo "OS Configuration (AUTO)"
	osspecific config "$@"
fi


