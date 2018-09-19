#!/bin/sh -e
. ./functions.sh


depends_SLES() {
	echo >/dev/null
}
depends_RHEL() {
	[ -x /usr/bin/expect ] || yum install -y expect
}

trakapacheconf_SLES() {
	CONFDIR=/etc/apache2/conf.d
	CONF=$CONFDIR/t2018-$TRAKNS.conf
	echo $CONF
}
trakapacheconf_RHEL() {
	CONFDIR=/etc/httpd/conf.d
	CONF=$CONFDIR/t2018-$TRAKNS.conf
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
INST=`instname $SITE $ENV $TYPE$VER`
TRAKNS=`traknamespace $SITE $ENV`
TRAKPATH=`trakpath $SITE $ENV $TYPE$VER`
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
# find installer
installer=`locatefilestd $VER_*_R*_B*.zip`

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
# install T2018
echo "Creating"
echo $TMPDIR
echo ""
mkdir -p $TMPDIR/trakextract
cp expect/TrakVanillaT2018_Install_install.expect $TMPDIR/trakextract
chmod 755 $TMPDIR/trakextract/TrakVanillaT2018_Install_install.expect
olddir=`pwd`
cd $TMPDIR/trakextract
#${olddir}/expect/TrakVanillaT2018_Install_unzip.expect $installer
unzip -q -o $installer -d $TMPDIR/trakextract/
chown $CACHEUSR.$CACHEGRP $TMPDIR/trakextract -R

#$TMPDIR/trakextract/TrakVanillaT2018_Install_install.expect $INST $TMPDIR/trakextract $ENV $TRAKNS ${TRAKPATH} /trakcare
echo "
do \$system.OBJ.Load(\"$TMPDIR/trakextract/tkutils.xml\",\"fc\")
set vars(\"SRCDIR\") = \"$TMPDIR/trakextract\"
set vars(\"ENV\") = \"$ENV\"
set vars(\"NAMESPACE\") = \"$TRAKNS\"
set vars(\"TRAKDIR\") = \"${TRAKPATH}\"
set vars(\"WEBDIR\") = \"${TRAKPATH}/web\"
set vars(\"DBDIR\") = \"${TRAKPATH}/db\"
set vars(\"WEBURL\") = \"/trakcare\"
set vars(\"CREATEANLTNAMESPACE\") = \"N\"
do setup^tkutils(.vars)
Y
Y
"| /sbin/runuser -l cachesys -c "ccontrol session $INST -U\"USER\""

cd ${olddir}
rm -r $TMPDIR/trakextract

# change web/ directory to use site code (and possibly create lc symlink)
cd ${TRAKPATH}/web/custom/
mv $TRAKNS/ $SITE_UC
cd ${olddir}

# change config in Configuration Manager
./expect/TrakVanillaT2018_Install_cleanup.expect $INST $TRAKNS $SITE_UC ${TRAKPATH}/web/custom/$SITE_UC/cdl

# fix web/ permissions
chown $CACHEUSR.$CACHEGRP ${TRAKPATH}/web -R
find ${TRAKPATH}/web -type d -exec chmod 775 {} \;
find ${TRAKPATH}/web -type f -exec chmod 664 {} \;

