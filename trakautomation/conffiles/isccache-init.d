#!/bin/sh
#
# chkconfig: 2345 25 10

# description: Startup/shutdown script for ISC Cache \
#              ISC Cache.
#
### BEGIN INIT INFO
# Provides: isccache
# Required-Start: $remote_fs
# Required-Stop:  $remote_fs
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description: ISC Cache
# Description:    Start/Stop the ISC Cache instances
### END INIT INFO

#
# Glen Pitt-Pladdy (InterSystems) 20130618
# Based on HP ServiceGuard by Greg King
#

#
# NOTE: this script is a sample script--be sure to test and verify
# 	that this script works for your installation.
#
# NOTE: Set "startinst" varliable below to be the names of the Cache instances to start at boot
#
# NOTE: Set "cleanstop" to 1 or 0 according to the documenation

# put the instances to start on boot in here
startinst="
"
cleanstop=1 # cleanstop=1 means YES use ccontrol stop, =0 means use FORCE

cco_list="/usr/bin/ccontrol list"	# get Cache instance details
cco_qlist="/usr/bin/ccontrol qlist"	# get Cache instance details
cco_start="/usr/bin/ccontrol start"	# start a Cache instance
if [[ ${cleanstop} = 0 ]]; then
	cco_stop="/usr/bin/ccontrol force" # stop a Cache instance with force
else
	cco_stop="/usr/bin/ccontrol stop" # stop a Cache instance
fi
cco_force="/usr/bin/ccontrol force"	# force an instance down

HOST=`hostname`
TTY=`tty`

type=$1					# function type (start|stop)


###############################################################################
# Function: log_message
# This function is used to log a timestamped message
###############################################################################

function log_message
{	
	currDate=`date +'%b %d %Y %T : '`
	echo "$currDate$*" 
	echo "$currDate$*" >>/tmp/log
}

###############################################################################
# Function: start_cache
#
#    "/etc/cmcluster/<pkg>/cache.ksh "
#
# This function is used to start the CACHE instance.
###############################################################################

function start_cache
{
	ret=0
	# find all running instances - we must stop them all
	for inst in $startinst; do
		fullstatus=`${cco_qlist} ${inst} | awk -F ^ {'print $4'}`
		basedir=`${cco_qlist} ${inst} | awk -F ^ {'print $2'}`
		runstatus=`echo ${fullstatus} | awk -F , {'print $1'}`
		running=0 
		#
		# If Cache' is already running, then exit with success but note this.
		#
		if [[ ${runstatus} = running* ]]
		then
			log_message "INFO: Cache: ${inst} already running on ${HOST}...will exit with success"
			log_message ".......examine ${basedir}/mgr/cconsole.log and other logs"
			running=1
		fi
		log_message "INFO: Starting Cache - ${inst} - on ${HOST}" 
		${cco_start} ${inst} quietly
		status=$?

		if [[ ${status} = 1 && ${running} = 1 ]]
		then
			continue
		fi
		case $status in
			1)
			log_message "ERROR: Failed to start Cache - ${inst} - from ${basedir}"
			log_message ".......examine ${basedir}/mgr/cconsole.log and other logs"
			ret=1
		;;
			0)
			log_message "INFO: Cache instance: ${inst} running on ${HOST}"
		;;
		esac
	done
	exit $ret
}

###############################################################################
# Function: stop_cache
#
#    "/etc/cmcluster/<pkg>/cache.sh "
#
# Shutdown Cache
###############################################################################

function stop_cache
{
	ret=0
	# find all running instances - we must stop them all
	for inst in `${cco_qlist} | awk -F ^ {'print $1'}`; do
		basedir=`${cco_qlist} ${inst} | awk -F ^ {'print $2'}`
		fullstatus=`${cco_qlist} ${inst} | awk -F ^ {'print $4'}`
		runstatus=`echo ${fullstatus} | awk -F , {'print $1'}`

		if [[ ${runstatus} != running* ]]; then
			log_message "INFO: Cache instance: ${inst} not running--continue anyway..."
		fi
		log_message "INFO: Stopping Cache instance: ${inst} on ${HOST}"
		${cco_stop} ${inst} quietly
		status=$?
		[ -x ${basedir}/bin/clmanager ] && ${basedir}/bin/clmanager reinstall
		case $status in
			1)
			log_message "ERROR: Cache instance: ${inst} -- failed to stop cleanly"
			log_message ".......examine ${basedir}/mgr/cconsole.log and other logs"
			${cco_force} ${inst} quietly
			fstatus=$?
			if [[ $fstatus = 0 ]]
				then
				log_message "INFO: Cache instance: ${inst} -- forced down successfully"
				continue
			fi
			log_message "ERROR: Cache instance: ${inst} -- forced stop failed"
			ret=1
		;;
			0)
			log_message "INFO: Cache instance: ${inst} -- stopped on ${HOST}"
		;;
		esac
	done
	exit $ret
}


###############################################################################
# MAIN
#
# Test to see if we are being called to start the application, or stop the
# application.
###############################################################################

case ${type} in

	start)
	log_message "INFO: $0 executing on \"${HOST}\": Starting Cache"
	[ -d /var/lock/subsys/ ] && touch /var/lock/subsys/isccache
	start_cache
;;

	stop)
	log_message "INFO: $0 executing on \"${HOST}\": Stopping Cache"
	[ -f /var/lock/subsys/isccache ] && rm -f /var/lock/subsys/isccache
	stop_cache
;;

	*)
	echo  "Usage: ${0} <start|stop>"
	exit 1
;;
esac
