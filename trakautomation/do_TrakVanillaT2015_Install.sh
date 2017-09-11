#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


depends_SLES() {
	echo >/dev/null
}
depends_RHEL() {
	[ -x /usr/bin/expect ] || yum install -y expect
}

trakapacheconf_SLES() {
	CONFDIR=/etc/apache2/conf.d
	CONF=$CONFDIR/t2016-$TRAKNS.conf
	echo $CONF
}
trakapacheconf_RHEL() {
	CONFDIR=/etc/httpd/conf.d
	CONF=$CONFDIR/t2016-$TRAKNS.conf
	echo $CONF
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
INST=`instname $SITE $ENV DB$VER`
TRAKNS=`traknamespace $SITE $ENV`
TRAKPATH=`trakpath $SITE $ENV DB$VER`
echo "Vanilla Trak $VER Install for $SITE : $ENV ($INST: $TRAKNS)"
# check if we need to do this
if [ -f ${TRAKPATH}/web/default.htm -a -f ${TRAKPATH}/db/data/CACHE.DAT ]; then
	echo "Already appears to be web and databases installed"
	exit 0
fi
# get cache password if needed
if [ -z "$CACHEPASS" ]; then
	getpass "Caché Password" CACHEPASS 1
fi
# get Trak zip password if needed
if [ -z "$TRAKZIPPASS" ]; then
	getpass "TrakCare .zip Password" TRAKZIPPASS 1
fi
# find installer
#installer=`locatefilestd $VER_*_R*_B*.zip`
installer=/trak/iscbuild/installers/T2015_20150331_1957_ENXX_R0_FULL_B10.zip
#installer=/trak/iscbuild/installers/2014_20140902_1034_R4ENXX_B32.zip
#installer=/trak/iscbuild/installers/T2015_20150527_1736_DEV_ENXX_FULL_B231.zip
echo $installer
# check for target web/ directory
if [ ! -d ${TRAKPATH}/web ]; then
	echo "FATAL - expecting \"${TRAKPATH}/web/\" to be created with appropriate permissions in advance" >&2
	exit 1
fi
# install dependancies
osspecific depends
# check that expect is available
if [ ! -x /usr/bin/expect ]; then
	echo "FATAL - can't find executable /usr/bin/expect" >&2
	exit 1
fi
# check it's already installed
if [ -f ${TRAKPATH}/web/default.htm ]; then
	echo "Install (web/default.htm) already exists - skipping"
	exit 0
fi
# check we are root
if [ `whoami` != 'root' ]; then
	echo "Being run as user `whoami` - should be run as root"
	exit 1
fi
# install T2014
mkdir $TMPDIR/trakextract
cp expect/TrakVanillaT2015_Install_install.expect $TMPDIR/trakextract
chmod 755 $TMPDIR/trakextract/TrakVanillaT2015_Install_install.expect
olddir=`pwd`
cd $TMPDIR/trakextract
${olddir}/expect/TrakVanillaT2014_Install_unzip.expect $installer
chown $CACHEUSR.$CACHEGRP $TMPDIR/trakextract -R

$TMPDIR/trakextract/TrakVanillaT2015_Install_install.expect $INST $TMPDIR/trakextract $ENV $TRAKNS ${TRAKPATH} /trakcare
cd ${olddir}
rm -r $TMPDIR/trakextract

# fix up database naming to UK convention
ccontrol stop $INST nouser
UCSITE=`echo $SITE | tr '[:lower:]' '[:upper:]'`
sed -i "s/^$TRAKNS=$ENV-DATA,$ENV-APPSYS/$TRAKNS=$TRAKNS-DATA,$TRAKNS-APPSYS/" ${TRAKPATH}/hs/cache.cpf
sed -i "s/^$ENV-/$TRAKNS-/" ${TRAKPATH}/hs/cache.cpf
sed -i "s/\(Global_.*\|Routine_.*\|Package_.*\)=$ENV-/\1=$TRAKNS-/" ${TRAKPATH}/hs/cache.cpf
./expect/TrakVanillaT2014_Install_start.expect $INST

# change web/ directory to use site code (and possibly create lc symlink)
cd ${TRAKPATH}/web/custom/
mv $TRAKNS/ $SITE_UC
#ln -s $SITE_UC $SITE_LC
cd ${olddir}

# change config in Configuration Manager
./expect/TrakVanillaT2014_Install_cleanup.expect $INST $TRAKNS $SITE_UC ${TRAKPATH}/web/custom/$SITE_UC/cdl

# fix web/ permissions
chown $CACHEUSR.$CACHEGRP ${TRAKPATH}/web -R
find ${TRAKPATH}/web -type d -exec chmod 2770 {} \;
find ${TRAKPATH}/web -type f -exec chmod 660 {} \;

## install the apache config
#osspecific trakapacheconf
##apacheconf=`osspecific trakapacheconf`
#if [ -d $CONFDIR -a -f /opt/cspgateway/bin/CSP.ini ]; then
#	apacheconf=$CONF
#	cp conffiles/apache-t2016.conf $apacheconf
#	chmod 644 $apacheconf
#	# apply custom settings
#	sed -i 's/TRAKWEBAPP/\/trakcare/g' $apacheconf
#	sed -i "s/TRAKWEBDIR/`path2regexp ${TRAKPATH}/web`/g" $apacheconf
#	# add in CSP config
#	ini_update.pl /opt/cspgateway/bin/CSP.ini \
#		'[APP_PATH:/trakcare]GZIP_Compression=Enabled' \
#		'[APP_PATH:/trakcare]GZIP_Exclude_File_Types=jpeg gif ico png' \
#		'[APP_PATH:/trakcare]Response_Size_Notification=Chunked Transfer Encoding and Content Length' \
#		'[APP_PATH:/trakcare]KeepAlive=No Action' \
#		'[APP_PATH:/trakcare]Non_Parsed_Headers=Enabled' \
#		'[APP_PATH:/trakcare]Alternative_Servers=Disabled' \
#		"[APP_PATH:/trakcare]Alternative_Server_0=1~~~~~~$INST" \
#		"[APP_PATH:/trakcare]Default_Server=$INST" \
#		'[APP_PATH_INDEX]/trakcare=Enabled'
#else
#	echo "Skipping Trak Config (no Apache and/or CSP)"
#fi
#osspecific apacherestart





