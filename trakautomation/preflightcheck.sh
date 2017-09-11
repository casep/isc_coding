#!/bin/sh -e
. ./functions.sh

# sort params
preflightargs "$@"
# do basic santiy check
if [ ! -d preflightchecks.d/ ]; then
	echo "FATAL - expecting to find at inidicidual checks in checks.d/" >&2
	exit 1
fi


# on with the show....
echo "Pre-flight check report"
echo "#######################"
date
echo "$0 $@"
echo "Possible prefixes: =CRITICAL, =ALERT, =NOTE"
echo
# get platform info (avoid it re-trying later)
eval `Platform2ENV.pl`
# run through all checks available
for script in preflightchecks.d/*.sh; do
	echo "Executing $script"
	./$script "$@" || echo "*** ERROR - exit status $?"
	echo
done

