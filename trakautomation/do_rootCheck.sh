#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


if [ `whoami` != 'root' ]; then
	echo "Root Check failed - running as `whoami` instead of root"
	exit 1
fi
exit 0


