#!/bin/sh -e
# resets the config and re-runs OSconfigAUTO
. ./functions.sh


check_LINUX() {
	SYSCTLCONF=/etc/sysctl.conf
#	LIMITSCONF=/etc/security/limits.conf
#	if [ -f ${SYSCTLCONF}.original -o -f ${LIMITSCONF}.original ]; then return 0; fi
	if [ -f ${SYSCTLCONF}.original ]; then return 0; fi
	return 1
}

# TODO RHEL has a /etc/security/limits.d/ and it would be neater to use that TODO but then we don't need to set that in recent distros
config_LINUX() {
	# backup config
	oldconf=${SYSCTLCONF}.retune-`date +%Y%m%d-%H%M%S`
	echo "Backing up to \"$oldconf\""
	cp -a ${SYSCTLCONF} $oldconf
	# move back the original
	mv ${SYSCTLCONF}.original ${SYSCTLCONF}
	# reset config
	echo 67108864 >/proc/sys/kernel/shmmax
	echo 16384 >/proc/sys/kernel/msgmni
	echo 32768 >/proc/sys/kernel/msgmax
	echo 32768 >/proc/sys/kernel/msgmnb
	echo 0 >/proc/sys/vm/nr_hugepages
	# set the original parameters active
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
}




# check args
if [ $# -ne 1 ]; then
	echo "Usage: $0 <aditional HugePages KiB>" >&2
	exit 1
fi


# go for it
if ! osspecific check; then
	echo "Auto-configuration doesn't appear to exist - perhaps you actually want to do that first"
	exit 0
else
	echo "OS Reconfiguration"
	echo "NOTE: this will based on the most recent start-up of Caché instances"
	echo "WARNING - this will replace the OS configuration files with the originals,"
	echo "before applying a new config."
	echo "That means any changes since install will be blown away."
	echo
	echo "Hit Return to continue / Ctrl-C to abort"
	read
	osspecific config "$@"
	echo "Starting reconfiguration"
	./do_OSconfigAUTO.sh "$@"
fi


