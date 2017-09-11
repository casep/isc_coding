#!/bin/sh -e
# Checks main Trak database has a Custom.TCToolsD mapping to SYSCONFIG

. ./functions.sh


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare Custom.TCToolsD mapping (UK Region Specific)"
checkfieldquit TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview $FUNCTIONS
checkfieldquit UK $REGION
# would have bailed above if no match
osspecific checkmapping 'Global_Custom.TCToolsD' 'SYSCONFIG'

