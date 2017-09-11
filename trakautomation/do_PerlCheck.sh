#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh



if ! which perl >/dev/null 2>/dev/null; then
	echo "Perl Check failed - we do need a minimal install of Perl for consistency between OS'"
	exit 1
fi
exit 0


