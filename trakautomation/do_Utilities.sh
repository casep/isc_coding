#!/bin/sh -e
# Install extra utilities (eg. used for tuning)
# Glen Pitt-Pladdy (ISC)
. ./functions.sh



install_SLES() {
	installdepends /usr/bin/ftp lukemftp
	installdepends /usr/bin/snmpwalk net-snmp
	installdepends /usr/bin/scipt util-linux
}
install_RHEL() {
	installdepends /usr/bin/ftp ftp
	installdepends /usr/bin/snmpwalk net-snmp-utils
	installdepends /usr/bin/scipt util-linux-ng
}


echo "########################################"
echo "Install Utilities"
installdepends /usr/bin/sar sysstat
installdepends /usr/bin/telnet telnet
installdepends /usr/bin/strace strace
installdepends /usr/sbin/tcpdump tcpdump
installdepends /usr/bin/wget wget
#installdepends /usr/bin/w3m w3m
installdepends /usr/bin/screen screen
installdepends /usr/bin/unzip unzip

osspecific install


