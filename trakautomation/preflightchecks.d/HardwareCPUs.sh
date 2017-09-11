#!/bin/sh -e
# Checks for CPUs
# Suggestion from LucaP - often VMs are built with 1 CPU
# webserver - 2 PLATFORM_cpus
# databse server - 4 PLATFORM_cpus
# print server - 4 PLATFORM_cpus (3 slots + OS/General)

. ./functions.sh


check_Unix () {
	eval `Platform2ENV.pl`
	min=2
	alert=0
	ok=0
	if listunion database $FUNCTIONS; then
		alert=4
		ok=6
	elif listunion app $FUNCTIONS; then
		ok=2
	fi
	if listunion print $FUNCTIONS; then
		if [ $alert -ge 4 ]; then
			# assume will share some with other functions
			alert=$(($alert+2))
		else
			alert=4
		fi
		if [ $ok -ge 4 ]; then
			ok=$(($alert+3))
		else
			ok=4
		fi
	fi
	if listunion web $FUNCTIONS; then
		if [ $alert -ge 2 ]; then
			# assume will share some with other functions
			alert=$(($alert+1))
		else
			alert=2
		fi
		if [ $ok -ge 2 ]; then
			ok=$(($alert+1))
		else
			ok=2
		fi
	fi
	# make sure minimum values are set
	if [ $alert -lt 2 ]; then alert=2; fi
	if [ $ok -lt 2 ]; then ok=2; fi
	# check how we did
	if [ -z "$PLATFORM_cpus" -o -z "$PLATFORM_processor" ]; then
		echo "=CRITICAL - Processor Type or Count not found. Is somehting wrong?"
	elif [ $PLATFORM_cpus -eq 1 ]; then
		echo "=CRITICAL - Only a single $PLATFORM_processor CPU found. Typical VM config error."
	elif [ $PLATFORM_cpus -lt $min ]; then
		echo "=CRITICAL - $PLATFORM_cpus $PLATFORM_processor CPU found, with minimum requirement $min."
	elif [ $PLATFORM_cpus -lt $alert ]; then
		echo "=ALERT - $PLATFORM_cpus $PLATFORM_processor CPU found, with requirement $alert."
	elif [ $PLATFORM_cpus -ge $ok ]; then
		echo "=OK - $PLATFORM_cpus $PLATFORM_processor CPU found"
	else
		echo "=NOTE - $PLATFORM_cpus $PLATFORM_processor CPU found, suggested $ok, but probably ok"
	fi
}


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - CPU Number"
checkfieldquit OSSkeleton,OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,web,print,preview,analytics $FUNCTIONS
# would have bailed above if no match
osspecific check

