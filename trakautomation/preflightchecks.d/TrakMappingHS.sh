#!/bin/sh -e
# Checks main Trak database has a Package_HS mapping to HSLIB

. ./functions.sh


# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - TrakCare Package HS mapping"
checkfieldquit TrakUpgrade,TrakBuild,GoLive $STAGE
checkfieldquit database,app,print,preview $FUNCTIONS
# would have bailed above if no match
osspecific checkmapping 'Package_HS' '.HSLIB'

