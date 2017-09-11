#!/bin/sh -e
# installs bundles of snmp config and scripts in directory given as argument
# Glen Pitt-Pladdy (ISC)
. ./functions.sh


check_LinuxGen() {
	SNMPDCONF=/etc/snmp/snmpd.conf
	if [ -f ${SNMPDCONF}.original.$cactitemplate ]; then return 0; fi
	return 1
}
check_SLES() { check_LinuxGen; return $?; }
check_RHEL() { check_LinuxGen; return $?; }

install_LinuxGen() {
	# create master cron job if needed
	cronjob=/etc/snmp/local-snmp-cronjob
	if [ ! -f $cronjob ]; then
		echo '#!/bin/sh' >$cronjob
		echo '# InterSystems auto-created SNMP cronjob' >>$cronjob
		echo '# Glen Pitt-Pladdy (InterSystems) 20130115' >>$cronjob
		echo >>$cronjob
		chmod +x $cronjob
	fi
	# create /var/local/snmp + cache if needed
	if [ ! -d /var/local/snmp/cache ]; then
		mkdir -p /var/local/snmp/cache
		mkdir -p /var/local/snmp/isc
		chown $CACHEUSR. /var/local/snmp/isc
		# on RH/Suse snmpd runs as root (!) so just clear world read/exec
		chmod o-rwx /var/local/snmp/ -R
		# this is needed for low priveledge users ($CACHEUSR) to get to isc/
		chmod o+rwx /var/local/snmp/
	fi
	# create crontab if needed
	crontab=/etc/cron.d/local-snmp
	if [ ! -f $crontab ]; then
		echo '# InterSystems auto-created SNMP crontab' >>$crontab
		echo '# Glen Pitt-Pladdy (InterSystems) 20130115' >>$crontab
		echo "*/5 * * * * root $cronjob" >$crontab
	fi
	# template install
	# copy files listed in 'filelist'
	target=/etc/snmp
	for file in `cat $cactitemplate/filelist`; do
		cp -i $cactitemplate/$file $target/
		# add cron job
# TODO these need args and some need backgrounding TODO
# TODO need to be able to pick up a default cronjob line to add in TODO
		echo $file | if grep -q -- '-cron$'; then
			echo cron $file
			if grep -q $target/$file $cronjob; then
				echo "Config exists for $cactitemplate in $cronjob" >&2
				echo "Update manaully if needed" >&2
				echo "Press Enter to continue...." >&2
				read
			else
				echo >>$cronjob
				if [ -f $cactitemplate/${file}-exec ]; then
					# we have an explicit way of running this that we need to follow
					cat $cactitemplate/${file}-exec >>$cronjob
				else
					# generic - just execute this
					echo $target/$file >>$cronjob
				fi
			fi
		fi
	done
	# put in snmpd config
	srcconfig=$cactitemplate/snmpd.conf
	dstconfig=$target/snmpd.conf
	if grep -q "^# InterSystems auto-install for $cactitemplate$" $target/snmpd.conf; then
		echo "Config exists for $cactitemplate in $dstconfig" >&2
		echo "Update manaully from $srcconfig if needed" >&2
		echo "Press Enter to continue...." >&2
		read
	else
		echo >>$dstconfig
		echo "#InterSystems auto-install for $cactitemplate" >>$dstconfig
		cat $srcconfig >>$dstconfig
	fi
}
install_SLES() { install_LinuxGen; return $?; }
install_RHEL() { install_LinuxGen; return $?; }

restart_LinuxGen() {
	sleep 10
	service snmpd restart
}
restart_SLES() { restart_LinuxGen; return $?; }
restart_RHEL() { restart_LinuxGen; return $?; }



echo "########################################"
# check for directory matching argument
if [ -z "$1" -o ! -d "$1" -o ! -f "$1/snmpd.conf" -o ! -f "$1/filelist" ]; then
	echo "usage: $0 <cacti- directory>" >&2
	echo "Must contain a snmpd.conf and filelist" >&2
	exit 1
fi
cactitemplate=`echo $1 | sed 's/\/$//'`


# configure snmpd
if osspecific check $cactitemplate; then
	echo "snmpd Configuration Exists for $cactitemplate"
	exit 0
else
	echo "snmpd Install/Configuration for $cactitemplate"
	# backup config
	cp -a ${SNMPDCONF} ${SNMPDCONF}.original.$cactitemplate
	# install / config
	osspecific install
	# restart snmpd
	osspecific restart
fi


