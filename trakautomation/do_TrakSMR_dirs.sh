#!/bin/sh -e
# directories for SMR loads
# Glen Pitt-Pladdy (ISC)
. ./functions.sh

echo "########################################"
echo "Trak SMR Directories"
TRAKPATH=`trakpath $SITE $ENV DB$VER`


makewithperms() {
	fullpath=${TRAKPATH}/store/$1
	mkdirifneeded $fullpath
	chown $CACHEUSR.$CACHEGRP $fullpath
	chmod 2770 $fullpath
}

# SMRs
makewithperms extracts/SMR00
makewithperms extracts/SMR01
makewithperms extracts/SMR02
makewithperms extracts/SMR04
# New Ways
makewithperms extracts/NewWays 
# Data Checks
makewithperms extracts/DataChecks
# ISD Ref files
makewithperms loadfiles/ISDvalidation 
# New Ways
makewithperms loadfiles/NewWays


