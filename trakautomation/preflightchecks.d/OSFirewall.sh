#!/bin/sh -e
# Checks for CPUs
# Suggestion from LucaP - checking firewall config
# TODO webserver does not need to check SMP / Superserver TODO

. ./functions.sh


# check if firewall is enabled
checkenabled_SLES() {
	# check if it's enabled
	enabledinit=`chkconfig SuSEfirewall2_init | sed 's/^.* \+//'`
	enabledsetup=`chkconfig SuSEfirewall2_setup | sed 's/^.* \+//'`
	if [ ! -z "$enabledinit" -a $enabledinit = 'off' -a ! -z "$enabledsetup" -a $enabledsetup -a 'off' ]; then
		echo disabled
	else
		# check config
		CONF=/etc/sysconfig/SuSEfirewall2
		# check for no external devices
		devint=`grep '^FW_DEV_INT=' $CONF | cut -d= -f2`
		if [ -z "$devint" ]; then
			echo "=CRITICAL - no FW_DEV_INT config line found. Is somehting wrong?"
		els
			if [ $devint != '""' ]; then
				echo "=NOTE - Found Internal devices $devint. Not checking further."
			else
				echo enabled
			fi
		fi
	fi
}
checkenabled_RHEL() {
	# check if it's enabled
	enabledtables4=`chkconfig --list iptables | sed 's/^.*:on[\t ].*$/on/' | sed 's/^.*:off[\t ].*$/off/'`
#	enabledtables6=`chkconfig --list ip6tables | sed 's/^.*:on .*$//' | sed 's/^.*:off .*$//'`
#	if [ ! -z "$enabledtables4" -a "$enabledtables4" = 'off' -a ! -z "$enabledtables6" -a "$enabledtables6" = 'off' ]; then
	if [ ! -z "$enabledtables4" -a "$enabledtables4" = 'off' ]; then
		echo disabled
	else
		echo enabled
	fi
}
checkenabled_AIX() {
	# we assume no firewall for AIX
	echo disabled
}


# services passed as PROTO:port/svcname pairs
findservice_SLES() {
	SVCCONFD=/etc/sysconfig/SuSEfirewall2.d/services
	CONF=/etc/sysconfig/SuSEfirewall2
	# we need to find which service matches any of our services
	for service in $@; do
		proto=`echo $service | cut -d: -f1 | tr '[:lower:]' '[:upper:]'`
		port=`echo $service | cut -d: -f2`
#echo $proto $port
		services=`grep -l "^$proto=\"$port\"$" $SVCCONFD/* | cat`
		if [ -z "$services" ]; then continue; fi
		services=`basename $services`
#echo $services
		for accept in `grep '^FW_CONFIGURATIONS_EXT=' $CONF | cut -d= -f2 | cut -d\" -f2`; do
			for need in $services; do
				if [ $need == $accept ]; then
					echo accept
					return 0
				fi
			done
		done
	done
	# TODO check for hard-coded ports in $CONF
	# failed to find anything
	echo none
	return 0
}
findservice_RHEL() {
	CONF=/etc/sysconfig/iptables
	# we need to find which service matches any of our services
	for service in $@; do
		proto=`echo $service | cut -d: -f1 | tr '[:upper:]' '[:lower:]'`
		port=`echo $service | cut -d: -f2`
#echo $proto $port
		for fwport in `grep -- '-A INPUT' $CONF | grep -- '-j ACCEPT' \
			| grep -- "-p $proto" | grep -- "--dport " \
			| sed 's/^.*--dport \+//' | sed 's/ .*$//'`; do
			minport=`echo  $fwport | cut -d: -f1`
			maxport=`echo  $fwport | cut -d: -f2`
			if echo $port | grep -q '^[0-9]\+$'; then
				if [ $port -ge $minport -a $port -le $maxport ]; then
					echo accept
					return 0
				fi
			fi
		done
	done
	# failed to find anything
	echo none
	return 0
}


# first arg is a descriptive string, remaining are possible proto:port pairs
requiredservice() {
	status=$1
	descr=$2
	shift 2
	if [ `osspecific findservice $@` == 'accept' ]; then
		echo "=OK - Config allowing \"$descr\" found"
	else
		echo "=$status - No config for \"$descr\" found"
	fi
}




# sanity check
preflightargs $@
# get on with the job
echo "*CHECK - Firewall"
checkfieldquit OSHandover,CacheBuild,TrakUpgrade,TrakBuild,GoLive $STAGE
#checkfieldquit database,app,print $FUNCTIONS	# always run this TODO maybe we should be sepcific about checks vs functions
# would have bailed above if no match
result=`osspecific checkenabled`
if echo $result | grep -q ^=; then
	# somehting went wrong so report it
	echo $result
elif echo $result | grep -q ^enabled$; then
	# need to do checks
	if listunion database,print,app $FUNCTIONS && ! listunion OSSkeleton,OSHandover $STAGE; then
#	if listunion database,print,app $FUNCTIONS; then
		for instinfo in `ccontrol qlist | awk 'BEGIN { FS="^"; OFS="^" }; { print $6,$7,$1 }' | sort`; do
			instname=`echo $instinfo | cut -d^ -f3`
			if [ $instname == 'CSP' ]; then continue; fi
			instss=`echo $instinfo | cut -d^ -f1`
			instsmp=`echo $instinfo | cut -d^ -f2`
			if [ $instss -eq 1972 ]; then ssname='tcp:intersystems-cache'; fi
			requiredservice ALERT "Caché Superserver ($instname)" tcp:$instss $ssname
			requiredservice ALERT "Caché SMP ($instname)" tcp:$instsmp
		done
	fi
	if listunion database $FUNCTIONS; then
		requiredservice NOTE 'Caché ISCAgent' tcp:2188
	fi
	requiredservice ALERT 'Secure Shell' tcp:22 tcp:ssh
	if listunion web,app,preview $FUNCTIONS; then
		requiredservice ALERT 'Web' tcp:80 tcp:www tcp:http tcp:443 tcp:https
	fi
	if listunion print $FUNCTIONS; then
		requiredservice ALERT 'CUPS' tcp:631 tcp:ipp
	fi
	if listunion database $FUNCTIONS; then
		requiredservice NOTE 'Network Filesystem (NFS)' tcp:2049 tcp:nfs
	fi
elif echo $result | grep -q ^disabled$; then
	echo "=NOTE - Firewall Disabled"
fi


