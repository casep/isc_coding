#!/bin/sh -e
# Checks main Trak database has a ERROR mapping to ZTEMP which avoids journalling large amounts of errors from bad customer customisation

. ./functions.sh


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare ERRORS mapping"
checkfieldquit TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview $FUNCTIONS
# would have bailed above if no match
osspecific checkmapping 'Global_ERRORS' 'ZTEMP'

