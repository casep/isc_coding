#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
# TODO work in progress TODO
. ./functions.sh
# our standard web application path is "/trakcare"
WEBAPPTRAK=/trakcare
WEBAPPPRT=/report


trakapacheconf_SLES() {
	CONFDIR=/etc/apache2/conf.d
	CONF=$CONFDIR/t2016-$TRAKNS.conf
	CONFPRT=$CONFDIR/t2016-EPS.conf
#	echo $CONF
}
trakapacheconf_RHEL() {
	CONFDIR=/etc/httpd/conf.d
	CONF=$CONFDIR/t2016-$TRAKNS.conf
	CONFPRT=$CONFDIR/t2016-EPS.conf
#	echo $CONF
}

apacherestart_SLES() {
	[ -x /usr/sbin/httpd2 ] && service apache2 restart
	return 0
}
apacherestart_RHEL() {
	[ -x /usr/sbin/httpd ] && service httpd restart
	return 0
}



echo "########################################"
if [ $# -lt 1 ]; then
	echo "Usage: $0 <DB|APP|APPn|PRT|PRTn> [DB server host:port if remote and not already configured in CSP Gateway]" >&2
	exit 1
fi
case $1 in
	DB)
		TYPE=$1
	;;
	APP|APP*)
		TYPE=$1
		APP=1
	;;
	PRT|PRT*)
		TYPE=$1
		PRT=1
	;;
	*)
		echo "Usage: $0 <DB|APP|APPn>" >&2
		exit 1
	;;
esac
# verify we can ping the database server if specified
if [ -n "$2" ]; then
	DBHOST=`echo $2 | cut -d: -f1`
	DBPORT=`echo $2 | cut -d: -f2`
	if ! ping -c 3 $DBHOST >/dev/null 2>&1; then
		echo "$0: FATAL - can't ping specified database server \"$DBHOST\"" >&2
		exit 1
	fi
fi
# calculate vital information
INST=`instname $SITE $ENV $TYPE$VER`
TRAKNS=`traknamespace $SITE $ENV`
TRAKPATH=`trakpath $SITE $ENV DB2016`
# on with the show
echo "Trak 2016 Apache & CSP config for $SITE : $ENV ($INST: $TRAKNS)"
# check if we need to do this
if [ ! -f ${TRAKPATH}/web/default.htm ]; then
	echo "Can't find the web/ directory \"${TRAKPATH}/web/\" with expected files"
	exit 1
fi
# check we are root
if [ `whoami` != 'root' ]; then
	echo "Being run as user `whoami` - should be run as root"
	exit 1
fi
# get config file location
osspecific trakapacheconf
# check if Apache config exists
if [ ! -d $CONFDIR ]; then
	echo "Can't find Apache config directory \"$COFDIR\""
	exit 1
fi
# CSP Gateway config
if [ ! -f /opt/cspgateway/bin/CSP.ini ]; then
	echo "Can't find CSP Gateway Config \"/opt/cspgateway/bin/CSP.ini\""
	exit 1
fi
# check for config and skip
if [ -f $CONF ]; then
	echo "Already configured: \"$CONF\" exists"
	exit 0
fi



if [ -n "$PRT" ]; then
	# This is a print/reporting install
	cp conffiles/apache-t2016report.conf $CONFPRT
	chmod 644 $CONFPRT
	# apply custom settings
	sed -i "s/REPORTWEBAPP/`path2regexp ${WEBAPPPRT}`/g" $CONFPRT
	sed -i "s/TRAKWEBAPP/`path2regexp ${WEBAPPTRAK}`/g" $CONFPRT
	sed -i "s/TRAKWEBDIR/`path2regexp ${TRAKPATH}/web`/g" $CONFPRT

	# add in CSP Gateway config
	ini_update.pl /opt/cspgateway/bin/CSP.ini \
		"[APP_PATH:${WEBAPPPRT}]GZIP_Exclude_File_Types=jpeg gif ico png" \
		"[APP_PATH:${WEBAPPPRT}]Response_Size_Notification=Chunked Transfer Encoding and Content Length" \
		"[APP_PATH:${WEBAPPPRT}]KeepAlive=No Action" \
		"[APP_PATH:${WEBAPPPRT}]Non_Parsed_Headers=Enabled" \
		"[APP_PATH:${WEBAPPPRT}]Alternative_Servers=Disabled" \
		"[APP_PATH:${WEBAPPPRT}]Alternative_Server_0=1~~~~~~$INST" \
		"[APP_PATH:${WEBAPPPRT}]Default_Server=$INST" \
		"[APP_PATH_INDEX]${WEBAPPPRT}=Enabled"
else
	# This must be a TrakCare isntall
	# always need the DB irrespective of if this is a Web, App or single-tier server
	# for single-tier this should already have been configured with the CSP Gateway install
	DBINST=`instname $SITE $ENV DB$VER`
	if [ "`ini_getparam.pl /opt/cspgateway/bin/CSP.ini SYSTEM_INDEX $DBINST 2>&1`" != 'Enabled' ]; then
		# we need to add this server which means we need address/port details
		if [ -z "$DBHOST" -o -z "$DBPORT" ]; then
			echo "$0: FATAL - don't have database host:port and not already configured for CSP Gateway" >&2
			exit 1
		fi
		# get cache password if needed when we have an outside DB
		if [ -z "$CACHEPASS" ]; then
			getpass "Caché Password" CACHEPASS 1
		fi
		# password appears to be ]]] prepended to base64
		DBPASS="]]]`echo -n "$CACHEPASS" | base64`"
	fi
	# add in CSP server config
	ini_update.pl /opt/cspgateway/bin/CSP.ini \
		"[SYSTEM_INDEX]$DBINST=Enabled" \
		"[$DBINST]Ip_Address=$DBHOST" \
		"[$DBINST]TCP_Port=$DBPORT" \
		"[$DBINST]Username=CSPSystem" \
		"[$DBINST]Password=$DBPASS" \
		"[$DBINST]Minimum_Server_Connections=3" \
		"[$DBINST]Maximum_Session_Connections=6"

	# install Trak config
	cp conffiles/apache-t2016.conf $CONF
	chmod 644 $CONF
	# apply custom settings
	sed -i "s/TRAKWEBAPP/`path2regexp ${WEBAPPTRAK}`/g" $CONF
	sed -i "s/TRAKWEBDIR/`path2regexp ${TRAKPATH}/web`/g" $CONF

	# add in CSP Gateway config
	ini_update.pl /opt/cspgateway/bin/CSP.ini \
		"[APP_PATH:${WEBAPPTRAK}]GZIP_Exclude_File_Types=jpeg gif ico png" \
		"[APP_PATH:${WEBAPPTRAK}]Response_Size_Notification=Chunked Transfer Encoding and Content Length" \
		"[APP_PATH:${WEBAPPTRAK}]KeepAlive=No Action" \
		"[APP_PATH:${WEBAPPTRAK}]Non_Parsed_Headers=Enabled" \
		"[APP_PATH:${WEBAPPTRAK}]Alternative_Servers=Disabled" \
		"[APP_PATH:${WEBAPPTRAK}]Alternative_Server_0=1~~~~~~$INST" \
		"[APP_PATH:${WEBAPPTRAK}]Default_Server=$INST" \
		"[APP_PATH_INDEX]${WEBAPPTRAK}=Enabled"

	# auto configure for APP with layout editor web path
	if [ -n "$APP" ]; then
		# this is am application server so needs configuration as a web server for layout editor
		# enable alias in Apache config
		sed -i 's/^#\(Alias .\+layouteditor\/ \)/\1/' $CONF
		# CSP Gateway config - note this web application will also need to be created on the database instance
		ini_update.pl /opt/cspgateway/bin/CSP.ini \
			"[APP_PATH:${WEBAPPTRAK}layouteditor]GZIP_Compression=Enabled" \
			"[APP_PATH:${WEBAPPTRAK}layouteditor]GZIP_Exclude_File_Types=jpeg gif ico png" \
			"[APP_PATH:${WEBAPPTRAK}layouteditor]Response_Size_Notification=Chunked Transfer Encoding and Content Length" \
			"[APP_PATH:${WEBAPPTRAK}layouteditor]KeepAlive=No Action" \
			"[APP_PATH:${WEBAPPTRAK}layouteditor]Non_Parsed_Headers=Enabled" \
			"[APP_PATH:${WEBAPPTRAK}layouteditor]Alternative_Servers=Disabled" \
			"[APP_PATH:${WEBAPPTRAK}layouteditor]Alternative_Server_0=1~~~~~~$INST" \
			"[APP_PATH:${WEBAPPTRAK}layouteditor]Default_Server=$INST" \
			"[APP_PATH_INDEX]${WEBAPPTRAK}layouteditor=Enabled"
	fi
fi


osspecific apacherestart





