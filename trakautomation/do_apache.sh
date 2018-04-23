#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


check_SLES() {
	STCONF=/etc/apache2/conf.d/iscstatus.conf
	if [ -x /usr/sbin/httpd2 -a -f $STCONF ]; then return 0; fi
	return 1
}
check_RHEL() {
	STCONF=/etc/httpd/conf.d/iscstatus.conf
	if [ -x /usr/sbin/httpd -a -f $STCONF ]; then return 0; fi
	return 1
}

install_SLES() {
	installdepends /usr/sbin/httpd2 apache2
}
install_RHEL() {
	installdepends /usr/sbin/httpd httpd mod_ssl
}

config_SLES() {
	# enable/disable based on ISC docs
	yast2 http-server modules enable=alias,authz_host,dir,log_config,mime,negotiation,setenvif
	yast2 http-server modules disable=autoindex,cgi,env,include,userdir
	# enable mod_rewrite, mod_status, mod_expires, mod_ssl, but possibly not expires if we never want to deploy optimisations
	yast2 http-server modules enable=rewrite,status,expires,ssl
# TODO leftovers - probably safe to disable: suexec,actions,auth_basic,authn_file,authz_user,authz_groupfile,authn_dbm
	# enalbe ExtendedStatus for mod_status
	echo "# Added by InterSystems Build" >>$STCONF
	echo "<IfModule mod_status.c>" >>$STCONF
	echo "	ExtendedStatus On" >>$STCONF
	echo "</IfModule>" >>$STCONF
	# add apache to $CACHEGRP so it can read files without messing with it's ownership
	usermod --add-to-group $CACHEGRP wwwrun
}
config_RHEL() {
	# disable unneeded modules (RH approach)
	CONF=/etc/httpd/conf/httpd.conf
	cp -a $CONF $CONF.original-do_apache
	#TODO missing setenvif, ssl
	for module in `grep '^LoadModule ' /etc/httpd/conf/httpd.conf | awk '{print $2}' | sed s/_module//`
	do
		# check if it's one we need based on ISC docs
		if listunion $module alias,authz_host,dir,log_config,mime,negotiation,setenvif; then continue; fi
		# check if it's one we need based on UK requirements
		if listunion $module rewrite,status,expires,ssl; then continue; fi
		sed -i "s/^\(LoadModule ${module}_module \)/#disabled ISC Automation# \\1/" $CONF
	done
	# take out RH config that breaks
	for items in IndexOptions AddIconByEncoding AddIconByType AddIcon DefaultIcon ReadmeName HeaderName IndexIgnore; do
		sed -i "s/^\\($items \\)/#disabled ISC Automation# \\1/" $CONF
	done
	# enalbe ExtendedStatus for mod_status
	echo "# Added by InterSystems Build" >>$STCONF
	echo "<IfModule mod_status.c>" >>$STCONF
	echo "	<Location /server-status>" >>$STCONF
	echo "		SetHandler server-status" >>$STCONF
	echo "		Order deny,allow" >>$STCONF
	echo "		Deny from all" >>$STCONF
	echo "		Allow from 127.0.0.1" >>$STCONF
	echo "		Allow from ::1" >>$STCONF
	echo "		Allow from 10.111.1.114" >>$STCONF	
	echo "		Allow from localhost" >>$STCONF
	echo "	</Location>" >>$STCONF
	echo "	ExtendedStatus On" >>$STCONF
	echo "</IfModule>" >>$STCONF
	# in RHEL mod_rewrite, mod_status, mod_expires are already enabled
	# add apache to $CACHEGRP so it can read files without messing with it's ownership
	usermod --group $CACHEGRP apache
}

enable_SLES() {
	chkconfig apache2 on
	service apache2 restart
	# work around possible race condition with apache starting up
	sleep 15
}
enable_RHEL() {
	chkconfig httpd on
	service httpd restart
	# work around possible race condition with apache starting up
	sleep 15
}



echo "########################################"
# get it onboard
if osspecific check; then
	echo "Apache Configuration Exists"
	exit 0
else
	echo "Apache Install/Configuration"
	# install apache2 TODO should we use fork or threads?
	osspecific install
	# create balnk config
	osspecific config
	# enable apache
	osspecific enable
fi


