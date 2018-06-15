#!/bin/sh -e
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


check_LINUX() {
	NRPECFG=/etc/nagios/nrpe.cfg
	INSTALLPATH=/usr/local/nagios/plugins
	if [ -f ${NRPECFG}.original ]; then return 0; fi
	return 1
}

install_SLES() {
	if [ ! -x /usr/sbin/nrpe ]; then
		installdepends /usr/sbin/nrpe nagios-nrpe
		usermod --add-to-group $CACHEGRP nagios
	fi
	if [ ! -d $INSTALLPATH ]; then
		mkdir -p $INSTALLPATH
		cp -i nagios-plugins/* $INSTALLPATH
	fi
}
install_RHEL_6_3() {
	if [ ! -x /usr/sbin/nrpe ]; then
		yum install -y 'perl(Digest::HMAC)' 'perl(Digest::SHA1)' 'perl(Socket6)'
		# install RPMForge RPMs for this
		yum localinstall -y nagios-nrpe-RHEL6.3/*.rpm
		usermod -G $CACHEGRP nagios
	fi
	if [ ! -d $INSTALLPATH ]; then
		mkdir -p $INSTALLPATH
		cp -i nagios-plugins/* $INSTALLPATH
	fi
}
install_RHEL_6_4() {
	if [ ! -x /usr/sbin/nrpe ]; then
		yum install -y 'perl(Digest::HMAC)' 'perl(Digest::SHA1)' 'perl(Socket6)'
		# install RPMForge RPMs for this
		yum localinstall -y nagios-nrpe-RHEL6.4/*.rpm
		usermod -G $CACHEGRP nagios
	fi
	if [ ! -d $INSTALLPATH ]; then
		mkdir -p $INSTALLPATH
		cp -i nagios-plugins/* $INSTALLPATH
	fi
}
install_RHEL_6_5() {
	install_RHEL_6_4
}

install_RHEL_7_1() {
        if [ ! -x /usr/sbin/nrpe ]; then
                yum install -y 'perl(Digest::HMAC)' 'perl(Digest::SHA1)' 'perl(Socket6)'
                # install RPMForge RPMs for this
                yum localinstall -y nagios-nrpe-RHEL7.1/*.rpm
                usermod -G $CACHEGRP nagios
        fi
        if [ ! -d $INSTALLPATH ]; then
                mkdir -p $INSTALLPATH
                cp -i nagios-plugins/* $INSTALLPATH
        fi

}
install_CentOS_7_1() {
install_RHEL_7_1
}
install_RHEL_7_3() {
        if [ ! -x /usr/sbin/nrpe ]; then
                yum install -y 'perl(Digest::HMAC)' 'perl(Digest::SHA1)' 'perl(Socket6)'
                # install RPMForge RPMs for this
                yum localinstall -y nagios-nrpe-RHEL7.3/*.rpm
                usermod -G $CACHEGRP nagios
        fi
        if [ ! -d $INSTALLPATH ]; then
                mkdir -p $INSTALLPATH
                cp -i nagios-plugins/* $INSTALLPATH
        fi

}

install_RHEL_7_4() {
        if [ ! -x /usr/sbin/nrpe ]; then
                yum install -y 'perl(Digest::HMAC)' 'perl(Digest::SHA1)' 'perl(Socket6)'
                # install RPMForge RPMs for this
                yum localinstall -y nagios-nrpe-RHEL7.4/*.rpm
                usermod -G $CACHEGRP nagios
        fi
        if [ ! -d $INSTALLPATH ]; then
                mkdir -p $INSTALLPATH
                cp -i nagios-plugins/* $INSTALLPATH
        fi

}

install_RHEL_7_5() {
        if [ ! -x /usr/sbin/nrpe ]; then
                yum install -y 'perl(Digest::HMAC)' 'perl(Digest::SHA1)' 'perl(Socket6)'
                # install RPMForge RPMs for this
                yum localinstall -y nagios-nrpe-RHEL7.5/*.rpm
                usermod -G $CACHEGRP nagios
        fi
        if [ ! -d $INSTALLPATH ]; then
                mkdir -p $INSTALLPATH
                cp -i nagios-plugins/* $INSTALLPATH
        fi

}

install_CentOS_7_3() {
install_RHEL_7_3
}

#install_RHEL() {
#	if [ ! -x /usr/sbin/nrpe ]; then
#		installdepends /usr/sbin/nrpe nagios-nrpe
#		usermod --group $CACHEGRP nagios
#	fi
#	if [ ! -d $INSTALLPATH ]; then
#		mkdir -p $INSTALLPATH
#		cp -i nagios-plugins/* $INSTALLPATH
#	fi
#}

paths_SLES() {
	PLUGINPATH=/usr/lib/nagios/plugins
}
paths_RHEL() {
	PLUGINPATH=/usr/lib64/nagios/plugins
}


# <address/range for nrpe access> <fuctions> <max licenses> <episodes/year>
# if max licenses and episodes/year are "0" then assumes not to be a Trak
# TODO create sane thresholds based on episodes/year TODO
#config_SLES() {
#	# append onto config
#	echo >>${NRPECFG}
#	echo "# ISC Config" >>${NRPECFG}
#	for net in `ip addr show | grep "inet .* eth[0-9]*$" | sed 's/^.* inet //' | cut -d' ' -f 1`; do
#		echo "rocommunity public "`ip2netaddr $net` >>${NRPECFG}
#	done
#	echo "master agentx" >>${NRPECFG}
#	echo "agentXSocket tcp:localhost:705" >>${NRPECFG}
#}
config_LINUX() {
	sed -i "s/^\\(allowed_hosts\\)=.*$/\\1=$1/" ${NRPECFG}
	sed -i 's/^\(command\[check_hda1\]\)=/#\1=/' ${NRPECFG}
	# baseline would be ~170 processes on an idle SuSE system, so 200/250 would be a good baseline before episodes
	sed -i 's/^\(command\[check_total_procs\]=\/usr\/lib\(64\)\?\/nagios\/plugins\/check_procs\) .*$/\1 -w 500 -c 600/' ${NRPECFG}
	echo >>${NRPECFG}
	echo "# ISC Config" >>${NRPECFG}
	echo "command[check_mcelog]=$INSTALLPATH/check_mcelog" >>${NRPECFG}
	echo "command[check_disks]=$PLUGINPATH/check_disk -w 85 -c 90 -W 60 -C 80" >>${NRPECFG}
	echo "command[check_swap]=$PLUGINPATH/check_swap -w 95 -c 80" >>${NRPECFG}
	count=1
	for server in `grep ^server /etc/ntp.conf | grep -v '127\.127\.1\.0' | awk '{print $2}'`; do
		echo "command[check_ntp_time$count]=$PLUGINPATH/check_ntp_time -H $server -w 3 -c 15" >>${NRPECFG}
		count=$(($count+1))
	done
	# backups if a path exists TODO depricated
#	if [ -d /trak/$1/$2/backup/ ]; then
#		echo "command[check_trakonlinebackup]=$INSTALLPATH/check_trakonlinebackup /trak/$1/$2/backup/" >>${NRPECFG}
#	fi
	# Caché & Trak specific checks
	if listunion $2 DB; then
		echo "command[check_smb]=$PLUGINPATH/contrib/check_smb.sh" >>${NRPECFG}
	fi
	if listunion $2 DB,APP,PRT,ANALYTICS,PREVIEW; then
		echo "command[check_cache_instances]=$INSTALLPATH/check_cache_instances" >>${NRPECFG}
		echo "command[check_cache_licenses]=$INSTALLPATH/check_cache_licenses" >>${NRPECFG}
		echo "command[check_cache_errors]=$INSTALLPATH/check_cache_errors" >>${NRPECFG}
	fi
	if listunion $2 DB; then
		echo "command[check_tcmonitor_age]=$INSTALLPATH/check_tcmonitor_age 90 300" >>${NRPECFG}
		echo "command[check_tcmonitor_interfaces]=$INSTALLPATH/check_tcmonitor_interfaces 5" >>${NRPECFG}
		echo "command[check_tcmonitor_licenses_used]=$INSTALLPATH/check_tcmonitor_licenses_used $(($3*85/100)) $(($3*95/100))" >>${NRPECFG}
# 5 20
		echo "command[check_tcmonitor_dayapperror]=$INSTALLPATH/check_tcmonitor_dayapperror \$ARG \$ARG" >>${NRPECFG}
		echo "command[check_tcmonitor_perf]=$INSTALLPATH/check_tcmonitor_perf 1 5" >>${NRPECFG}
		echo "command[check_tcmonitor_print_errors]=$INSTALLPATH/check_tcmonitor_print_errors \$ARG1 \$ARG2" >>${NRPECFG}
#		echo "command[check_tcmonitor_print_hour]=$INSTALLPATH/check_tcmonitor_print_hour \$ARG1 \$ARG2" >>${NRPECFG}
#		echo "command[check_tcmonitor_print_min]=$INSTALLPATH/check_tcmonitor_print_min \$ARG1 \$ARG2" >>${NRPECFG}
#		echo "command[check_tcmonitor_print_progress]=$INSTALLPATH/check_tcmonitor_print_progress \$ARG1 \$ARG2" >>${NRPECFG}
		echo "command[check_tcmonitor_print_waiting]=$INSTALLPATH/check_tcmonitor_print_waiting \$ARG1 \$ARG2" >>${NRPECFG}
	fi
	if listunion $2 PRT; then
		echo "command[check_cups_queue]=$INSTALLPATH/check_cups_queue 3 10" >>${NRPECFG}
		echo "command[check_cups_queueage]=$INSTALLPATH/check_cups_queueage 3600 10800" >>${NRPECFG}
		echo "command[check_cups_disabled]=$INSTALLPATH/check_cups_disabled 1 5" >>${NRPECFG}
		echo "command[check_hotjvm]=$INSTALLPATH/check_hotjvm.sh" >>${NRPECFG}
	fi
	if listunion $2 WEB,APP,ANALYTICS,PREVIEW; then
		# checks on Apache
		echo nop >/dev/null
	fi
#	echo "" >>${NRPECFG}
}

enable_LinuxGen() {
	chkconfig nrpe on
	service nrpe start
}
enable_SLES() { enable_LinuxGen; return $?; }
enable_RHEL() { enable_LinuxGen; return $?; }



echo "########################################"
if [ $# -ne 4 ]; then
	echo "Usage: $0 <address/range for nrpe access> <functions> <max licenses> <episodes/year>" >&2
	echo "functions: DB (main TrakCare), APP, PRT, ANALYTICS, PREVIEW, others (no special functionality)" >&2
	exit 1
fi

# configure snmpd
if osspecific check; then
	echo "Nagios nrpe Configuration Exists"
	exit 0
else
	echo "Nagios nrpe Install/Configuration"
	# install
	osspecific install
	# backup config
	cp -a ${NRPECFG} ${NRPECFG}.original
	# add config
	osspecific paths
	osspecific config $@
	# enable and start
	osspecific enable
fi


