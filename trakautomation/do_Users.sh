#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh
# TODO check for NIS / LDAP in use TODO

# Standards for UK as discussed with LucaP 20130304
# users:
#	cacheusr -> owns cache
#	cachebackup -> used to call-in for backups
#	traksmb -> anonymous smb access (member of cachegrp)
# groups:
#	cachegrp -> owns cache
#	cachemgr -> can stop/start
#	trakcache -> can "sudo -u cacheusr"
#	trakprint -> CUPS admin



check_LINUX() {
	# assume all config exists - clear if not
	allconfig=1
	# assume no config exists - set if not
	someconfig=0
	# do checks
	usersrequired=0
	usersexist=0
	for user in $CACHESYSUSR $CACHEUSR $TRAKSMB $CACHEBACKUP; do
		# check status of this user
		if [ -z "$user"  ]; then
			# this is bad - should never happen
			echo "FATAL - got NULL user" >&2
			exit 1
		elif [ "$user" != '!' ]; then
			# user not disabled - should be valid
			usersrequired=$(($usersrequired+1))
		fi
		# check if they exist
		if grep -q "^$user:" /etc/passwd; then
			usersexist=$(($usersexist+1))
		fi
	done
	groupsrequired=0
	groupsexist=0
	for group in $CACHEGRP $CACHEMGR $TRAKCACHE $TRAKPRINT; do
		# check status of this user
		if [ -z "$group"  ]; then
			# this is bad - should never happen
			echo "FATAL - got NULL group" >&2
			exit 1
		elif [ "$group" != '!' ]; then
			# group not disabled - should be valid
			groupsrequired=$(($groupsrequired+1))
		fi
		# check if they exist
		if grep -q "^$group:" /etc/group; then
			groupsexist=$(($groupsexist+1))
		fi
	done
	# figure out the situation
	if [ $usersrequired -eq $usersexist -a $groupsrequired -eq $groupsexist ]; then
		# good stuff - nothing to do
		return 0
	elif [ $usersexist -eq 0 -a $groupsexist -eq 0 ]; then
		# nothing exists - full run
		return 2
	else
		# oops! partly (or over) configured - manual intervention will be needed
		return 1
	fi
}

config_LINUX() {
	UIDBASE=2000
	GIDBASE=2000
	# set the standard uids/gids (users/groups should already be set from functions.sh)
	if [ -z "$CACHEGRPID" ]; then export CACHEGRPID=$(($GIDBASE+0)); fi
	if [ -z "$CACHEMGRID" ]; then export CACHEMGRID=$(($GIDBASE+1)); fi
	if [ -z "$TRAKCACHEID" ]; then export TRAKCACHEID=$(($UIDBASE+2)); fi
	if [ -z "$TRAKPRINTID" ]; then export TRAKPRINTID=$(($UIDBASE+3)); fi

	if [ -z "$CACHEUSRID" ]; then export CACHEUSRID=$(($UIDBASE+0)); fi
	if [ -z "$CACHESYSUSRID" ]; then export CACHESYSUSRID=$(($UIDBASE+0)); fi
	if [ -z "$TRAKSMBID" ]; then export TRAKSMBID=$(($UIDBASE+1)); fi
	if [ -z "$CACHEBACKUPID" ]; then export CACHEBACKUPID=$(($UIDBASE+2)); fi
}

groupadd_SLES() {
	groupadd --preferred-gid $1 $2
}
groupadd_RHEL() {
	groupadd --gid $1 $2
}
useradd_SLES() {
		uid=$1
		username=$2
		shift 2
		useradd  --preferred-uid $uid $@ $username
}
useradd_RHEL() {
		uid=$1
		username=$2
		shift 2
		useradd  --uid $uid $@ $username
}





echo "########################################"
set +e
osspecific check
ret=$?
set -e
case $ret in
	0)
		echo "User/Group Configuration exists"
		exit 0
	;;
	1)
		echo "FATAL - Partial User/Group Configuration exists" >&2
		exit 1
	;;
	2)
		echo "User/Group Configuration"
		# set base UIDs/GIDs
		osspecific config
		# groups we need
		[ "$CACHEGRP" != '!' ] && osspecific groupadd $CACHEGRPID $CACHEGRP
		[ "$CACHEMGR" != '!' ] && osspecific groupadd $CACHEMGRID $CACHEMGR
		[ "$TRAKCACHE" != '!' ] && osspecific groupadd $TRAKCACHEID $TRAKCACHE
		[ "$TRAKPRINT" != '!' ] && osspecific groupadd $TRAKPRINTID $TRAKPRINT
#		groupadd --preferred-gid $(($GIDBASE+5)) trakuser
#		groupadd --preferred-gid $(($GIDBASE+7)) traksmb
		# users we need
		[ "$CACHEUSR" != '!' ] && osspecific useradd $CACHEUSRID $CACHEUSR -g $CACHEGRP -G $CACHEGRP --create-home
		[ "$CACHESYSUSR" != '!' ] && osspecific useradd $CACHESYSUSRID $CACHESYSUSR -g $CACHEGRP -G $CACHEMGR --create-home
		[ "$CACHEBACKUP" != '!' ] && osspecific useradd $CACHEBACKUPID $CACHEBACKUP -g $CACHEGRP -G $CACHEGRP --create-home
		[ "$TRAKSMB" != '!' ] && osspecific useradd $TRAKSMBID $TRAKSMB -g $CACHEGRP
#		useradd  --preferred-uid $(($UIDBASE+3)) -g cachegrp -G trakuser,cachemgr,cachegrp ensmanager
#		userensmanager=$?
#		useradd  --preferred-uid $(($UIDBASE+4)) -g cachegrp -G trakuser cacheuser
#		usercacheuser=$?
		# set passwords
#		if [ $userensmanager -eq 0 ]; then
#			echo ensmanager password
#			passwd ensmanager
#			echo
#		fi
#		if [ $usercacheuser -eq 0 ]; then
#			echo cacheuser password
#			passwd cacheuser
#			echo
#		fi
		exit 0
	;;
	*)
		echo "User/Group check returned unexpected value $ret" >&2
		exit 1
	;;
esac


