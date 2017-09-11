#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh
SMBTEMPLATE=conffiles/smb.conf


check_LINUX() {
	SMBMASTER=/etc/samba/smb.conf
	if [ -f $SMBMASTER.original ]; then return 0
	else return 1; fi
}

config_LINUX() {
	# install/update custom config TODO
	cp -a $SMBMASTER $SMBMASTER.original
	cat $SMBTEMPLATE $SMBTEMPLATE-$SITE >$SMBMASTER
	sed -i "s/DOMAIN/$DOMAIN/" $SMBMASTER
	sed -i "s/SERVERNAME/$SERVERNAME/" $SMBMASTER
	sed -i "s/DESCRIPTION/$DESCRIPTION/" $SMBMASTER
	# sepcific shares
	PATHESC=`path2regexp ${TRAKPATH}/store/temp/`
	sed -i "s/PATHTRAKTEMP/$PATHESC/" $SMBMASTER
	PATHESC=`path2regexp ${TRAKPATH}/store/trakreports/`
	sed -i "s/PATHREPORTS/$PATHESC/" $SMBMASTER
	PATHESC=`path2regexp ${TRAKPATH}/store/loadfiles/`
	sed -i "s/PATHLOADFILES/$PATHESC/" $SMBMASTER
#	PATHESC=`path2regexp ${TRAKPATH}/TODO`
#	sed -i "s/PATHAPPDATA/$PATHESC/" $SMBMASTER
	PATHESC=`path2regexp ${TRAKPATH}/store/extracts/`
	sed -i "s/PATHEXTRACTS/$PATHESC/" $SMBMASTER
#	PATHESC=`path2regexp ${TRAKPATH}/TODO`
#	sed -i "s/PATHTEMPLATES/$PATHESC/" $SMBMASTER
#	PATHESC=`path2regexp ${TRAKPATH}/TODO`
#	sed -i "s/PATHNEWWAYSEXT/$PATHESC/" $SMBMASTER
#	PATHESC=`path2regexp ${TRAKPATH}/TODO`
#	sed -i "s/PATHSCIATTACHMENTS/$PATHESC/" $SMBMASTER
#	PATHESC=`path2regexp ${TRAKPATH}/TODO`
#	sed -i "s/PATHUPLOAD/$PATHESC/" $SMBMASTER
#	PATHESC=`path2regexp ${TRAKPATH}/TODO`
#	sed -i "s/PATHICNET/$PATHESC/" $SMBMASTER
#	PATHESC=`path2regexp ${TRAKPATH}/TODO`
#	sed -i "s/PATHAPPDATAXFER/$PATHESC/" $SMBMASTER
	PATHESC=`path2regexp ${TRAKPATH}/web/custom/$SITECODE/XML`
	sed -i "s/PATHXMLIMEX/$PATHESC/" $SMBMASTER
	PATHESC=`path2regexp ${TRAKPATH}/web/`
	sed -i "s/PATHWEB/$PATHESC/" $SMBMASTER
#	PATHESC=`path2regexp ${TRAKPATH}/TODO`
#	sed -i "s/PATHPRINTOUT/$PATHESC/" $SMBMASTER
	PATHESC=`path2regexp ${TRAKPATH}/store/usertemp/`
	sed -i "s/PATHUSERTEMP/$PATHESC/" $SMBMASTER
	# master config customisation TODO
}

enable_LINUX() {
	chkconfig smb on
	service smb start
}



echo "########################################"
# check for args
if [ $# -ne 4 ]; then
	echo "Usage: $0 <SMB DOMAIN> <SMB Server name> <Server Description> <Site Code - eg. LUHNT>" >&2
	exit 1
fi
# go for it
if osspecific check; then
	echo "Samba Configuration Exists"
	exit 0
else
	echo "Samba Install/Configuration"
	# get parameters
	DOMAIN=$1
	SERVERNAME=$2
	DESCRIPTION=$3
	SITECODE=$4
	TRAKPATH=`trakpath $SITE $ENV DB$VER`
	# check for config template
	if [ ! -f $SMBTEMPLATE-$SITE -o ! -f $SMBTEMPLATE ]; then
		echo "FATAL - can't find templates \"$SMBTEMPLATE\" and/or \"$SMBTEMPLATE-$SITE\" in local directory" >&2
		exit 1
	fi
	# install samba
	installdepends /usr/sbin/smbd samba
	# config
	osspecific config
	# enable samba daemons
	osspecific enable
fi


