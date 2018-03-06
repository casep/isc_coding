#!/bin/sh -e
# InterSystems TrakCare UK zCustom.SnapBackup Call-in script
# This is a call-in script that does error checking and returns the status specified
# Glen Pitt-Pladdy (InterSystems) 20131118
# Carlos Sepulveda 20160218, update for instance down to integrate with VBA

# set exist codes - some backup systems require non-standard ones
EXITFAILURE=1
EXITSUCCESS=0

# what user to use for call-ins - if unset this will not "su"
CACHEUSER=cachebackup

# the timestamp we use
TIMESTAMP=`date +%Y%m%d-%H%M%S`

usage() {
	echo "Usage: $0 <Freeze|Thaw|History|JournalSwitch> <Instance|_ALL> [Additional Options]" >&2
	exit $EXITFAILURE
}

# args: <Freeze|Thaw|History> <INSTANCE> [Additional Options]
execute() {
	local instance=`ccontrol qlist | cut -d^ -f1 | grep -i $2`
	if [ -z "$instance" ]; then
		badinstance=1
		backuperror=1
		echo "ERROR - Instance \"$2\" not found" >&2
		return 1
	fi
	status=`ccontrol qlist | grep -i ^$2^ | cut -d^ -f4 | cut -d, -f1`
	if [ -z "$status" -o "$status" != "running" ]; then
		backuperror=0
		echo "ERROR - Instance \"$2\" not running (status: $status)" >&2
		return 0
	fi
	cachedir=`ccontrol qlist | grep -i ^$2^ | cut -d^ -f2`
	tmpdir=$cachedir/mgr/Temp
	if [ ! -d $tmpdir ]; then
		backuperror=1
		echo "ERROR - Instance \"$2\" can't find Temp directory ($tempdir)" >&2
		return 1
	fi
	statusfile=$tmpdir/zCustom.SnapBackup-$TIMESTAMP-$$-$1_Status.txt
	if [ -f $statusfile ]; then
		backuperror=1
		echo "ERROR - Instance \"$2\" already has Status file ($statusfile)" >&2
		return 1
	fi
	# run the call-in
	echo "calling $1 for $instance"
	case $1 in
		Freeze)
			if [ -z "$CACHEUSER" ]; then
				csession $instance -U'%SYS' "##class(zCustom.SnapBackup).Freeze(\"$statusfile\")"
				ret=$?
			else
				su - $CACHEUSER -c "csession $instance -U'%SYS' '##class(zCustom.SnapBackup).Freeze(\"$statusfile\")'"
				ret=$?
			fi
		;;
		Thaw)
			if [ -z "$CACHEUSER" ]; then
				csession $instance -U'%SYS' "##class(zCustom.SnapBackup).Thaw(\"$statusfile\")"
				ret=$?
			else
				su - $CACHEUSER -c "csession $instance -U'%SYS' '##class(zCustom.SnapBackup).Thaw(\"$statusfile\")'"
				ret=$?
			fi
		;;
		History)
			if [ -n "$3" ]; then
				if [ -f "$3" ]; then
					if [ -z "$CACHEUSER" ]; then
						csession $instance -U'%SYS' "##class(zCustom.SnapBackup).History(\"$statusfile\",\"$3\")"
						ret=$?
					else
						su - $CACHEUSER -c "csession $instance -U'%SYS' '##class(zCustom.SnapBackup).History(\"$statusfile\",\"$3\")'"
						ret=$?
					fi
				else
					backuperror=1
					echo "ERROR - Instance \"$2\" specified log file \"$3\" not found" >&2
					return 1
				fi
			else
				if [ -z "$CACHEUSER" ]; then
					csession $instance -U'%SYS' "##class(zCustom.SnapBackup).History(\"$statusfile\")"
					ret=$?
				else
					su - $CACHEUSER -c "csession $instance -U'%SYS' '##class(zCustom.SnapBackup).History(\"$statusfile\")'"
					ret=$?
				fi
			fi
		;;
		JournalSwitch)
			if [ -z "$CACHEUSER" ]; then
				csession $instance -U'%SYS' "##class(zCustom.SnapBackup).JournalSwitch(\"$statusfile\")"
				ret=$?
			else
				su - $CACHEUSER -c "csession $instance -U'%SYS' '##class(zCustom.SnapBackup).JournalSwitch(\"$statusfile\")'"
				ret=$?
			fi
		;;
	esac
	echo "call complete (returns $ret) for $instance"
	# check how we did
	if [ $ret -ne 0 ]; then
		backuperror=1
		echo "ERROR - Instance \"$2\" call-in returned $ret" >&2
		[ -f $statusfile ] && rm $statusfile
		return $ret
	fi
	if [ ! -f $statusfile ]; then
		backuperror=1
		echo "ERROR - Instance \"$2\" created no status file ($statusfile)" >&2
		return 1
	fi
	# check the status file
	if grep ^FATAL $statusfile >&2; then
		backuperror=1
		rm $statusfile
		return 1
	elif grep ^ERROR $statusfile >&2; then
		backuperror=1
		rm $statusfile
		return 1
	elif grep ^WARNING $statusfile >&2; then
		rm $statusfile
	elif grep -q ^OK $statusfile; then
		rm $statusfile
	else
		backuperror=1
		cat $statusfile >&2
		rm $statusfile
		return 1
	fi
	
	# we got success (possibly with a warning)
	return 0
}


#############################################################################
#                            main
#############################################################################


# check arguments
if [ $# -lt 2 ]; then
	usage
fi
FUNCTION=$1
INSTANCE=$2
shift 2
case $FUNCTION in
	Freeze|Thaw|JournalSwitch)
		if [ $# -ne 0 ]; then
			usage
		fi
	;;
	History)
		# expecting optional logfile
		if [ $# -eq 1 -a ! -f "$1" ]; then
			usage
		elif [ $# -gt 1 ]; then
			usage
		fi
	;;
	*) usage ;;
esac


# run the commands according to the instances
badinstance=0
backuperror=0
if [ "$INSTANCE" = '_ALL' ]; then
	for instance in `ccontrol qlist | cut -d^ -f1`; do
		echo "** $FUNCTION $instance $@ **"
		set +e
		execute $FUNCTION $instance "$@"
		set -e
	done
else
	echo "** $FUNCTION $INSTANCE $@ **"
	execute $FUNCTION $INSTANCE "$@"
fi
# sort the overall status
echo
if [ $backuperror -eq 0 ]; then
	echo "* $FUNCTION Complete"
	exit $EXITSUCCESS
else
	echo "* $FUNCTION Complete with ERRORS - see above"
	exit $EXITFAILURE
fi

