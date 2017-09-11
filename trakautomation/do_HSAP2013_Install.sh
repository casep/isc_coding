#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./cachecommon.sh




echo "########################################"
CACHEDIR=hs
cacheconfig "$@"
echo "HSAP Install for $SITE : $ENV : $TYPE ($INST)"

# get cache password if needed
if [ -z "$CACHEPASS" -a $TYPE != 'CSP' ]; then
	getpass "Caché Password" CACHEPASS
fi
# find installer
if [ -z "$VERSTR" ]; then
	# no specific version specified - use generic
	installer=`locatefilestd "HSAP-2013.*-hscore*-\`cacheos\`.tar.gz"`
else
	# got a specific version pattern to match
	installer=`locatefilestd "HSAP-$VERSTR-*-\`cacheos\`.tar.gz"`
fi
echo "Found Installer: $installer"
# install dependancies and sanity check
osspecific depends
sanitycheck

# create minimal directories
[ $CSPONLY -ne 1 ] && environmentdirs

# install Caché
installCache expect/HSAP2013_Install

# install ZSTU and init script
installZSTU
installinit


