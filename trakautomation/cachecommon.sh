# Glen Pitt-Pladdy (ISC)
# code that is used common to all Caché versions

. ./functions.sh


depends_LINUX() {
echo depends
	installdepends /usr/bin/expect expect
}


cspconfig_SLES() {
	CSPCONF=/etc/apache2/conf.d/isccspgateway.conf
	touch $CSPCONF
	echo $CSPCONF
}
cspconfig_RHEL() {
	CSPCONF=/etc/httpd/conf.d/isccspgateway.conf
	touch $CSPCONF
	echo $CSPCONF
}


apacherestart_SLES() {
	service apache2 restart
}
apacherestart_RHEL() {
	service httpd restart
}


# find the Caché OS string
cacheos() {
	osspecific cacheos
}
# support rountines
cacheos_RHEL() { echo lnxrhx64; }
cacheos_SLES() { echo lnxsusex64; }
cacheos_Ubuntu() { echo lnxsusex64; }
cacheos_AIX() { echo ppc64; }


sanitycheck() {
	# check that expect is available
	if [ ! -x /usr/bin/expect ]; then
		echo "FATAL - can't find executable /usr/bin/expect" >&2
		exit 1
	fi
	# check it's already installed
	if [ -f ${TRAKPATH}/$CACHEDIR/cache.cpf ]; then
		echo "Instance already exists - skipping"
		exit 0
	fi
	# check we are root
	if [ `whoami` != 'root' ]; then
		echo "Being run as user `whoami` - should be run as root"
		exit 1
	fi
}


environmentdirs() {
	mkdirifneeded ${TRAKPATH}/$CACHEDIR true
	chown $CACHEUSR.$CACHEGRP $TRAKPATH/$CACHEDIR
	chmod 775 $TRAKPATH/$CACHEDIR
	mkdirifneeded ${TRAKPATH}/db true
	chown -R $CACHEUSR.$CACHEGRP $TRAKPATH/db
	chmod -R 755 $TRAKPATH/db
	# search primary journal locations
	for dir in jrn/pri/ jrn/ db/jrn/pri/ db/jrn/ $CACHEDIR/jrn/pri; do
		if [ -d $TRAKPATH/$dir -a -z "$prijrndir" ]; then
			prijrndir=$TRAKPATH/$dir
		fi
	done
	if [ -z "$prijrndir" ]; then
		echo "NOTE - no Primary Journal directory found"
	else
		chown -R $CACHEUSR.$CACHEGRP $prijrndir
		chmod -R 770 $prijrndir
	fi
	# search alternate journal locations
	for dir in jrn/alt/ db/jrn/alt/ $CACHEDIR/jrn/alt; do
		if [ -d $TRAKPATH/$dir -a -z "$altjrndir" ]; then
			altjrndir=$TRAKPATH/$dir
		fi
	done
	if [ -z "$altjrndir" ]; then
		echo "NOTE - no Alternate Journal directory found"
	else
		chown -R $CACHEUSR.$CACHEGRP $altjrndir
		chmod -R 770 $altjrndir
	fi
	# look for wij location(s)
	for dir in wij/ $CACHEDIR/wij/; do
		if [ -d $TRAKPATH/$dir -a -z "$wijdir" ]; then
			wijdir=$TRAKPATH/$dir
		fi
	done
	if [ -z "$wijdir" ]; then
		echo "NOTE - no WIJ directory found"
	else
		chown -R $CACHEUSR.$CACHEGRP $wijdir
		chmod -R 770 $wijdir
	fi
}


setCSPbasics() {
	# basig general config for CSP Gateway
	ini_update.pl /opt/cspgateway/bin/CSP.ini \
		'[SYSTEM]Server_Response_Timeout=900' \
		'[SYSTEM]Queued_Request_Timeout=900' \
		'[SYSTEM]System_Manager=*.*.*.*' \
		'[SYSTEM]Username=CSPGwAdmin' \
		'[SYSTEM]Password='
#		'[SYSTEM]SHM=NONE'
}


installCache() {
	expectprefix=$1
	# create extract areay
	olddir=`pwd`
	mkdir -p /tmp/cacheextract
	cd /tmp/cacheextract
	# extract - this way of extracting a tarball is needed for AIX compatibility
	gzip --decompress --stdout "$installer" | tar -xf -
	if [ $CSPONLY -ne 1 ]; then
		# database install
		if [ $CSP -eq 1 ]; then
			echo "Installing with CSP"
			${olddir}/${expectprefix}_withcsp.expect $INST ${TRAKPATH}/$CACHEDIR `osspecific cspconfig`
			# update CSP basics
			setCSPbasics
			# restart apache to make sure new config is in
			osspecific apacherestart
		else
			echo "Installing without CSP"
			${olddir}/${expectprefix}_nocsp.expect $INST ${TRAKPATH}/$CACHEDIR
		fi
	elif [ $CSP -eq 1 ]; then
		# standalone CSP
		echo "Installing Stand-alone CSP Gateway"
		cd dist/csp/
		${olddir}/${expectprefix}_csponly.expect `osspecific cspconfig`
		# update CSP basics
		setCSPbasics
		# restart apache to make sure new config is in
		osspecific apacherestart
	fi
	cd ${olddir}
	# cleanup
	rm -r /tmp/cacheextract
}


installZSTU() {
	# install ZSTU template
	if [ $CSPONLY -ne 1 ]; then
		./expect/genericCacheLoadXML.expect $INST '%SYS' `pwd`/conffiles/ZSTU.xml
	fi
}

installinit() {
	# install the init script if needed
	if [ $CSPONLY -ne 1 ]; then
		if [ ! -f /etc/init.d/isccache ]; then
			cp -n conffiles/isccache-init.d /etc/init.d/isccache
			chmod +x /etc/init.d/isccache
			chkconfig isccache on
			service isccache start
		fi
		echo "NOTE - Instance $INST has not been added to /etc/init.d/isccache to start at boot"
	fi
}








