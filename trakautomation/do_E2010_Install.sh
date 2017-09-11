#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./cachecommon.sh




echo "########################################"
CACHEDIR=ensemble
cacheconfig "$@"
echo "E2010 Install for $SITE : $ENV : $TYPE ($INST)"
# TODO we don't support CSP only installs at this point 
if [ $TYPE = 'CSP' ]; then
	echo "$0: FATAL - doesn't currently support Type \"CSP\"" >&2
	exit 1
fi

# get cache password if needed
if [ -z "$CACHEPASS" -a $TYPE != 'CSP' ]; then
	getpass "Caché Password" CACHEPASS
fi
# find installer
if [ -z "$VERSTR" ]; then
	# no specific version specified - use generic
	installer=`locatefilestd "ensemble-2010.*-\`cacheos\`.tar.gz"`
else
	# got a specific version pattern to match
	installer=`locatefilestd "ensemble-$VERSTR-\`cacheos\`.tar.gz"`
fi
echo "Found Installer: $installer"
# install dependancies and sanity check
osspecific depends
sanitycheck

# create minimal directories
[ $CSPONLY -ne 1 ] && environmentdirs

# install Caché
installCache expect/E2010_Install

# install ZSTU and init script
installZSTU
installinit


