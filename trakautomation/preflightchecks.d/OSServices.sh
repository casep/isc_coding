#!/bin/sh -e
# Suggestion from LucaP - checking for services that can be disabled / removed

. ./functions.sh

basics_SLES() {
	# work out needed services list
	serviceson=,cron,mta,ntp,sshd,syslog,nrpe,snmpd
	if [ -z "$PLATFORM_virtual" ]; then serviceson="$serviceson,mcelog"; fi
	servicesmaybe=,smartd
	servicesignore=,SuSEfirewall2_init,SuSEfirewall2_setup,acpid,dbus,earlysyslog,fbset,haldaemon,irq_balancer,java.binfmt_misc,kbd,microcode.ctl,network,network-remotefs,nscd,purge-kernels,random,vmware-tools,vmware-tools-thinprint
	# acpid ?
}

basics_RHEL() {
	# work out needed services list
	serviceson=,cron,mta,ntpd,sshd,syslog,nrpe,snmpd
	if [ -z "$PLATFORM_virtual" ]; then serviceson="$serviceson,mcelogd"; fi
	servicesmaybe=
	servicesignore=,dbus,iptables,ip6tables,lvm2-monitor,network,auditd,udev-post,rhnsd,rhsmcertd,vmware-tools,vmware-tools-thinprint,acpid
}


translate_SLES() {
	servicelist=$1
	servicelist=`echo $servicelist | sed 's/,mta,/,postfix,/g'`
	servicelist=`echo $servicelist | sed 's/,apache,/,apache2,/g'`
	# NOTE: nmb strictly isn't needed, and would need to be configured seperately - leave off for SuSE
	servicelist=`echo $servicelist | sed 's/,samba,/,smb,/g'`
	servicelist=`echo $servicelist | sed 's/,NFSSV,/,rpcbind,nfsserver,/g'`
	servicelist=`echo $servicelist | sed 's/,NFSCL,/,rpcbind,nfs,/g'`

#	servicelist=`echo $servicelist | sed 's/,,/,,/g'`
#	servicelist=`echo $servicelist | sed 's/,,/,,/g'`
#	servicelist=`echo $servicelist | sed 's/,,/,,/g'`
	echo $servicelist
}
# SLES services found enabled - decide on: auditd "haveged" "smbfs" "splash" "splash_early"
# SLES+RHEL perhaps "nmb" should be left disabled

translate_RHEL() {
	servicelist=$1
	servicelist=`echo $servicelist | sed 's/,mta,/,postfix,/g'`
	servicelist=`echo $servicelist | sed 's/,apache,/,httpd,/g'`
	servicelist=`echo $servicelist | sed 's/,syslog,/,rsyslog,/g'`
	servicelist=`echo $servicelist | sed 's/,cron,/,crond,/g'`
	servicelist=`echo $servicelist | sed 's/,dbus,/,messagebus,/g'`
	# NOTE: nmb strictly isn't needed, and would need to be configured seperately - leave off for RHEL
	servicelist=`echo $servicelist | sed 's/,samba,/,smb,/g'`
	servicelist=`echo $servicelist | sed 's/,NFSSV,/,rpcbind,nfs,/g'`
	servicelist=`echo $servicelist | sed 's/,NFSCL,/,rpcbind,nfslock,/g'`

#	servicelist=`echo $servicelist | sed 's/,,/,,/g'`
#	servicelist=`echo $servicelist | sed 's/,,/,,/g'`
#	servicelist=`echo $servicelist | sed 's/,,/,,/g'`
	echo $servicelist
}

status_SLES() {
	local service=$1
	local runlevel=$2
	local status=`chkconfig | grep "^$service " | awk '{print $2;}'`
	if echo $status | grep -q $runlevel; then
		status=on
	elif [ $status != 'on' ]; then
		status=off
	fi
	echo $status
}

status_RHEL() {
	local service=$1
	local runlevel=$2
	local status=`chkconfig | grep "^$service[^:alnum:-]" | sed "s/^.*\\t$runlevel:\\([^\\t]*\\)\\t.*$/\\1/"`
	echo $status
}


# check if firewall is enabled
checkservices_LINUX() {
	# get the basic config
	osspecific basics
	# add services based on functionality
	if listunion $FUNCTIONS web,app; then
		serviceson="$serviceson,apache"
		if ! listunion $FUNCTIONS database; then
			servicesmaybe="$servicesmaybe,NFSCL"
		fi
	fi
	if listunion $FUNCTIONS database; then
		serviceson="$serviceson,samba"
		servicesmaybe="$servicesmaybe,ISCAgent,NFSSV"
	fi
	if listunion $FUNCTIONS database,print,app; then
		serviceson="$serviceson,isccache"
	fi
	if listunion $FUNCTIONS print; then
		serviceson="$serviceson,cups"
	fi
	serviceson="$serviceson,"
	servicesmaybe="$servicesmaybe,"
	servicesignore="$servicesignore,"
	# translate generic service names to SLES specific
	serviceson=`osspecific translate $serviceson`
	servicesmaybe=`osspecific translate $servicesmaybe`
	servicesignore=`osspecific translate $servicesignore`
	# clean-up end comas
#	serviceson=`echo $serviceson | sed 's/^,//' | sed 's/,$//'`
#	servicesmaybe=`echo $servicesmaybe | sed 's/^,//' | sed 's/,$//'`
#	servicesignore=`echo $servicesignore | sed 's/^,//' | sed 's/,$//'`
	# check each service
	runlevel=`runlevel | cut -d' ' -f2`
	services=`chkconfig | awk '{print $1;}'`
	for service in $services; do
		status=`osspecific status $service $runlevel`
		# check status of this service
		if listunion $service $serviceson; then
			case $status in
				on) echo "=OK - Required Service \"$service\" is enabled" ;;
				off) echo "=ALERT - Required Service \"$service\" is disabled" ;;
			esac
			serviceson=`echo $serviceson | sed "s/,$service,/,/g"`
		elif listunion $service $servicesmaybe; then
			case $status in
				on) echo "=OK - Suggested Service \"$service\" is enabled" ;;
				off) echo "=NOTE - Suggested Service \"$service\" is disabled" ;;
			esac
			servicesmaybe=`echo $servicesmaybe | sed "s/,$service,/,/g"`
		elif ! listunion $service $servicesignore; then
			# not one we know about
			if [ $status == 'on' ]; then
				echo "=NOTE - Unused Service \"$service\" is enabled"
			fi
		fi
	done
	# services not covered
	for service in `echo $serviceson | sed 's/,/ /g'`; do
		echo "=ALERT - Required Service \"$service\" is not found"
	done
	for service in `echo $servicesmaybe | sed 's/,/ /g'`; do
		echo "=NOTE - Suggested Service \"$service\" is not found"
	done


}





# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Enabled Services"
checkfieldquit CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,print $FUNCTIONS	# always run this TODO maybe we should be sepcific about checks vs functions
# would have bailed above if no match
eval `Platform2ENV.pl`
osspecific checkservices


