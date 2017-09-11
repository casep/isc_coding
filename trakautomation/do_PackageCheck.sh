#!/bin/sh -e
# Check there is some valid package source
# Glen Pitt-Pladdy (ISC)

. ./functions.sh


check_RHEL() {
	# check for DVD
	normIFS=$IFS
	IFS=$'\n'
	for path in `grep '^baseurl=file:///' /etc/yum.repos.d/*.repo | cut -d: -f3 | sed 's/^\/\///' | sed 's/\\\ / /g'`; do
		if [ -f "${path}/listing" -o -f "${path}/Server/listing" ]; then
			echo "Found RHEL DVD on ${path}"
			return 0
		fi
	done
	IFS=$normIFS
	# check for DVD
	if [ "`subscription-manager list | grep '^Status:' | sed 's/^Status:\s*//' | sed 's/\s*$//'`" = 'Subscribed' ]; then
		echo "Found active RH Subscription"
		return 0
	fi
	# didn't find anything
	echo "FATAL - need the RHEL DVD mounted to install packages"
	return 1
}
check_SLES() {
	# check for DVD
	mountpoint=`mount | grep '^/dev/sr0' | cut -d' ' -f3`
	if [ -z "$mountpoint" ]; then
		echo "FATAL - can't find SLES DVD mountpoint" >&2
		return 1
	fi
	if [ -d "$mountpoint/suse" ]; then
		echo "Found SLES DVD on $mountpoint"
		return 0
	fi
	# check for non-DVD sources
	if [ `zypper ls -d | tail -n +3 | cut -d'|' -f8 | awk '{print $1}' | grep -v ^cd:/// | wc -l` -gt 0 ]; then
		echo "Found non-CD repo(s)"
		return 0
	fi
	# didn't find anything
	echo "FATAL - need the SLES DVD mounted or a subscribed repo to install packages"
	return 1
}

echo "Package Check"
osspecific check

